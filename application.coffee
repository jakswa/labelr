
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
    console.log "org and repo are not set! set em!"
    return

  path = "/repos/#{org}/#{repo}/issues"
  if storage('milestone')
    params ?= {}
    params.milestone = storage('milestone') 

  gethub(path, params, (data)->
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
  storage('top_sort', top) if storage('top_sort') != top
  storage('bottom_sort', bottom) if storage('bottom_sort') != bottom
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

populateOrgs = ->
  repoBtn = $('#switch-repo')
  orglist = $('#org')
  return if repoBtn.attr('disabled')

  buttonText = repoBtn.html()
  repoBtn.html('loading...').attr('disabled', 'disabled')
  gethub '/user/orgs', (data)->
    repoBtn.html(buttonText)
    orglist.find('.added').remove()
    for item in data.data
      orglist.prepend "<option class='added' value='#{item.login}'>#{item.login}</option>"
    repoBtn.hide()
    orglist.removeClass('hidden').show()
populateRepos = (ev, options={page: 1})->
  orglist = $('#org')
  val = orglist.val()

  if val == 'owner'
    path = '/user/repos'
    params = {type: 'owner'}
  else if val == 'member'
    path = '/user/repos'
    params = {type: 'member'}
  else
    path = "/orgs/#{val}/repos"

  params = $.extend(options, {sort: 'full_name'}, params)
  gethub path, params, (data) ->
    repolist = $('#repo')

    #orglist.hide()
    repolist.removeClass('hidden').show()

    contents = ''
    console.log "data length: #{data.data.length}"
    for item in data.data
      contents = contents + "<option class='added' value='#{item.full_name}'>#{item.name}</option>"

    repolist.find('option.added').remove() if options.page == 1
    populateRepos(null,{page: options.page + 1}) if data.data.length == 30
    repolist.append(contents)
chooseRepo = ->
  repos = $('#repo')
  [org, repo] = repos.val().split('/')

  storage('org', org)
  storage('repo', repo)
  populateMilestones()
populateMilestones = ->
  milestones = $('#milestone').show()
  $('#switch-milestone').hide()
  org = storage('org')
  repo = storage('repo')

  path = "/repos/#{org}/#{repo}/milestones"
  params = {state: 'open'}

  gethub path, params, (data) ->
    milestones.find('option.added').remove()
    for milestone in data.data
      ele = $("<option class='added' value=#{milestone.number}>#{milestone.title}</option>")
      if milestone.number == parseInt(storage('milestone'))
        ele.attr('selected', 'selected') 
      milestones.append ele
    milestones.removeClass('hidden').show()
milestoneChanged = ->
  milestone = $('#milestone')
  number = milestone.val()
  if number == 'none'
    localStorage.removeItem('milestone')
  else
    storage('milestone', number)
  window.fetchIssues()

promptRepos = () ->
  org = prompt("Type your github organization (ie 'vitrue'):")
  repo = prompt("Type a github repo name within #{org}:")
  storage('org', org)
  storage('repo', repo)
  fetchIssues()

gethub = (path, params, callback) ->
  callback = params unless callback
  params = $.extend({access_token: storage('token')}, params)
  purl = $.param(params)
  url = "https://api.github.com#{path}?#{purl}&callback=?"
  $.getJSON(url, callback)

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
  $('#switch-repo').click populateOrgs
  $('#switch-milestone').click populateMilestones
  $('#org').change populateRepos
  $('#repo').change chooseRepo
  $('#milestone').change milestoneChanged
  
  storage('top_sort', 'bug') unless storage('top_sort')
  storage('bottom_sort', 'enhancement') unless storage('bottom_sort')
  $('#top-sort').val(storage('top_sort'))
  $('#bottom-sort').val(storage('bottom_sort'))

  # time to start things up!
  # deciding based on 3 user states (in order below):
  # 1. having already oauthed with good token
  # 2. coming back from github with code
  # 3. new visitor needing redirect
  
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
