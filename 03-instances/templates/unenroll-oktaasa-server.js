const https = require("https")
const ssm = new (require('aws-sdk/clients/ssm'))()

const handler = (resolve, parser = JSON.parse) => (response) => {
  let data = ''

  response.on('data', d => {
    data += d
  })
  response.on('end', () => {
    resolve(parser(data))
  })
}

exports.handler = async function(event) {
  const body = JSON.parse(event.Records[0].body)
  
  if (body.Event === 'autoscaling:TEST_NOTIFICATION') {
    console.log('Test notification from autoscaling, skipping.')
    return
  }

  const instanceId = body.EC2InstanceId
  const projectName = JSON.parse(body.NotificationMetadata)['project_name']

  const ssmKeys = ['oktaasa-team', 'oktaasa-key-secret', 'oktaasa-key']
  const ssmData = await ssm.getParameters({
    Names: ssmKeys.map((key) => `/oktaasa/${environment}/$${key}`),
    WithDecryption: true
  }).promise()

  // returned parameters are not guaranteed to be in the order they were requested
  const [oktaTeam, oktaSecret, oktaId] = ssmKeys.map((name) => {
    return ssmData.Parameters.find((param) => param.Name.endsWith(name)).Value
  })

  const bearer = await new Promise(function(resolve, reject) {
    const body = JSON.stringify({
      key_id: oktaId,
      key_secret: oktaSecret,
    })
    https.request({
      hostname: 'app.scaleft.com',
      path: `/v1/teams/$${oktaTeam}/service_token`,
      method: 'post',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    }, handler(resolve))
    .on('error', (error) => reject(error))
    .end(body)
  })
  
  const servers = await new Promise(function(resolve, reject) {
    https.request({
      hostname: 'app.scaleft.com',
      path: `/v1/teams/$${oktaTeam}/projects/$${projectName}/servers/`,
      method: 'get',
      headers: {
        'Authorization': `Bearer $${bearer['bearer_token']}`
      }
    }, handler(resolve))
    .on('error', (error) => reject(error))
    .end()
  })
  
  const [serverId] = servers.list
    .filter((server) => server.instance_details.instance_id === instanceId)
    .map((server) => server.id)

  await new Promise(function(resolve, reject) {
    https.request({
      hostname: 'app.scaleft.com',
      path: `/v1/teams/$${oktaTeam}/projects/$${projectName}/servers/$${serverId}`,
      method: 'delete',
      headers: {
        'Authorization': `Bearer $${bearer['bearer_token']}`
      }
    }, handler(resolve, (d) => d))
    .on('error', (error) => reject(error))
    .end()
  })

  console.log(`Deleted server $${instanceId} ($${serverId}) from $${projectName}`)
}

