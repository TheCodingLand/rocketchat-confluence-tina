nconf = require("nconf")
btoa = require("btoa")

triggers = require './data/triggers.json'

cwd = process.cwd()
DEFAULTS_FILE = "#{__dirname}/data/defaults.json"

nconf.argv()
    .env()
    .file('defaults', DEFAULTS_FILE)

noResultsFound = [
  'I have no idea'
]

sanity_check_args = (msg) ->
  required_args = [
    "HUBOT_CONFLUENCE_USER"
    "HUBOT_CONFLUENCE_PASSWORD"
    "HUBOT_CONFLUENCE_HOST"
    "HUBOT_CONFLUENCE_PORT"
    "HUBOT_CONFLUENCE_SEARCH_SPACE"
    "HUBOT_CONFLUENCE_CONTEXT_ROOT"
  ]

  for arg in required_args
    if !nconf.get(arg)
      buf = "#hubot-confluence is not properly configured. #{arg} is not set."
      msg.reply buf
      return false
  msg.reply buf
  return true

query_tina = (query, links) ->
    tina_url = nconf.get("TINA_PIPELINE_URL")
    data = JSON.stringify({query: query, links:links})
    msg.http(tina_url, {timeout: timeout}).headers(headers).post(data) (e, res, body) ->
    if e
      msg.reply "Error: #{e}"
      return
   
    if res.statusCode isnt 200
      msg.send "Error processing your request"
      msg.send "Check hubot logs for more information"
      console.log("Status Code: " + res.statusCode)
      console.log("Response body:")
      console.log(body)
      return
    content = JSON.parse(body)
    msg.reply "#{content.results}"



search = (msg, query, text) ->
  msg.reply("seaching")
  query = clean_search(query)

  num_results = nconf.get("HUBOT_CONFLUENCE_NUM_RESULTS") or 3
  timeout = nconf.get("HUBOT_CONFLUENCE_TIMEOUT") or 2000
  space = nconf.get("HUBOT_CONFLUENCE_SEARCH_SPACE")
  if text
    text_search = "text~#{query}"
  else
    text_search = "title~#{query}"

  query_str = "type=page+and+space+in(#{space})+and+#{text_search}"
  query_str =  encodeURIComponent query_str
  suffix = "/content/search?os_authType=basic&cql=#{query_str}"
  url = make_url(suffix, true)
  headers = make_headers()
  msg.http(url, {timeout: timeout}).headers(headers).get() (e, res, body) ->
    if e
      msg.reply "Error: #{e}"
      return
   
    if res.statusCode isnt 200
      msg.send "Error processing your request"
      msg.send "Check hubot logs for more information"
      console.log("Status Code: " + res.statusCode)
      console.log("Response body:")
      console.log(body)
      return

 
    content = JSON.parse(body)

    if !content.results or content.results.length == 0
      #Fall back to text search
      if !text
        search(msg, query, true)
        return
      else
        msg.reply msg.random noResultsFound
        return

    count = 0
    links= []
    for result in content.results
      count += 1
      if count > num_results
        break
      link = make_url(result._links.webui, false)
      links.append(link)
      msg.reply "#{result.title} - #{link}"
    
    #query_tina(query,links)
    #here, i should query tina
    


make_headers = ->

  user = nconf.get("HUBOT_CONFLUENCE_USER")
  password = nconf.get("HUBOT_CONFLUENCE_PASSWORD")

  auth = btoa("#{user}:#{password}")

  ret =
    Accept: "application/json"
    Authorization: "Basic #{auth}"

clean_search = (query) ->
  query = query.replace(/[!?,.]/g, ' ')

make_url = (suffix, api) ->
  host = nconf.get("HUBOT_CONFLUENCE_HOST")
  port = nconf.get("HUBOT_CONFLUENCE_PORT")
  protocol = nconf.get("HUBOT_CONFLUENCE_PROTOCOL")
  context_root = nconf.get("HUBOT_CONFLUENCE_CONTEXT_ROOT")

  url = "#{protocol}://#{host}:#{port}/#{context_root}"
  # account for an empty context root
  if !context_root?.length
    url = "#{protocol}://#{host}:#{port}"
  if api
    url = "#{url}/rest/api#{suffix}"
  else
    url = "#{url}#{suffix}"

help = (msg) ->
  commands = [
    "confluence show triggers"
    "confluence help"
    "confluence search SEARCH PHRASE"
  ]
  buf = ""
  for command in commands
    buf += "#{command}\n"

  msg.reply buf

module.exports = (robot) ->

  robot.hear /confluence search (.*)/i, (msg) ->
    if !sanity_check_args(msg)
      return
    search(msg, msg.match[1], false)

  robot.hear /confluence help/i, (msg) ->
    help(msg)

  robot.hear /confluence show triggers/i, (msg) ->
    msg.reply triggers.join('\n')

  for trigger in triggers
    regex = new RegExp trigger, 'i'
    robot.hear regex, (msg) ->
      if !sanity_check_args(msg)
        return
      search(msg, msg.match[1], false)
