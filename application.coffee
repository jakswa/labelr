
# I'm getting tired of typing things like 'localStorage.getItem'
storage = (key, val) ->
  if val
    localStorage.setItem(key, val)
  else
    localStorage.getItem(key)
session = (key, val) ->
  if val
    sessionStorage.setItem(key, val)
  else
    sessionStorage.getItem(key)


# modified from http://stackoverflow.com/questions/1403888/get-url-parameter-with-jquery
getURLParameter = (name, params=location.search) -> 
  decodeURIComponent((new RegExp("[?|&]#{name}=([^&;]+?)(&|##|;|$)").exec(params) || [null,""] )[1].replace(/\+/g, '%20'))||null

window.fetchIssues = (options, params)->
  org = storage('org')
  repo = storage('repo')
  unless org and repo
    promptRepos() 
    return

  params = $.extend({access_token: storage('token'), milestone: 5}, params)
  purl = $.param(params)
  url = "https://api.github.com/repos/#{org}/#{repo}/issues?#{purl}&callback=?"

  $.getJSON(url,(data)->
    json = {issues: data.data}
    for issue in json.issues 
      issue.first_label_color = issue.labels[0].color if issue.labels.length > 0 
    labels = []
    $('#labels').html('')
    $.each(data.data, (index,value)->
      if "Bad credentials" == value
        storage("bad_token", true)
        redirectToOauth()
        return

      console.log value
      $.each(value.labels, (index,label)->
        if label.name not in labels
          $('#labels').append(ich.label(label)) 
          labels.push(label.name)
      )
    )
    $('#issues-holder').html(ich.issues(json))
  ).then(sortIssues)

redirectToOauth = ->
  document.location.href = "https://github.com/login/oauth/authorize?client_id=d96cd5d6ff897a568d80&scope=repo"

filterIssues = ->
  holder = $('#labels-holder')
  filtering_by_label = holder.hasClass('filtering-by-label')
  search_active = $("#search").val() != ''

  active_names = []
  holder.find('li.active').each(->
    active_names.push $(this).data('label-name')
  )

  issues = $('#issues > li')
  issues.each(->
    good = not filtering_by_label #start false if filtering by label
    issue = $(this)
    $(this).find('li.label').each(->
      good = true if filtering_by_label and $(this).data('label-name') in active_names
    )
    good = false if search_active and not
      issue.html().match(new RegExp($('#search').val(), 'i'))
    $(this).toggle(good)
  )

sortIssues = (ev)->
  top = $("#top-sort").val()
  bottom = $("#bottom-sort").val()
  issues = $('#issues > li')
  issues.each(->
    issue = $(this)
    up = false
    down = false
    $(this).find('li.label').each(->
      up = true if $(this).data('label-name') == top
      down = true if $(this).data('label-name') == bottom
    )
    if up
      issue.remove()
      $('#issues').prepend issue
    else if down
      issue.remove()
      $('#issues').append issue
  )

promptRepos = () ->
  org = prompt("Type your github organization (ie 'vitrue'):")
  repo = prompt("Type a github repo name within #{org}:")
  storage('org', org)
  storage('repo', repo)
  fetchIssues()

$(document).ready ->
  search = $('#search')
  code = getURLParameter("code")
  search.keyup (ev)->
    filterIssues()

  $('#app').on('click', 'li.label', (ev)->
    ev.stopPropagation()
    name = $(ev.currentTarget).data('label-name')
    if ev.shiftKey
      $('#top-sort').val(name)
      sortIssues()
      return
    else if ev.altKey
      $('#bottom-sort').val(name)
      sortIssues()
      return

    holder = $('#labels-holder')
    selector = "li[data-label-name='#{name}']"
    # styles
    target_label = holder.find(selector)
    removing = target_label.is('.active')
    actives = holder.find('li.active')
    actives.removeClass('active') unless ev.ctrlKey or (actives.length == 1 and removing)
    target_label.toggleClass('active')
    holder.toggleClass('filtering-by-label', holder.has('.active').length != 0)

    filterIssues()
  )

  $('#clear-labels').click(->
    $('#labels-holder').removeClass('filtering-by-label').
      find('li.active').removeClass('active')

    filterIssues()
  )
  $('#top-sort, #bottom-sort').keyup sortIssues


  # time to start things up!
  # deciding based on 3 user states (in order below):
  # 1. having already oauthed with good token
  # 2. coming back from github with code
  # 3. new visitor needing redirect
  
  # TODO: this right
  storage('org', 'vitrue')
  storage('repo', 'accounts')
  if storage('bad_token')
    localStorage.removeItem("bad_token")
    localStorage.removeItem('token')

  if storage("token")
    fetchIssues()
  else if (code)
    $.post("/oauth", {code: code}, (data)->
      if access_token = getURLParameter("access_token", "?#{data}")
        storage("token", access_token)
        fetchIssues()
      else
        console.log "Well that didn't work for #{code}... #{data}"
    )
  else
    redirectToOauth()
