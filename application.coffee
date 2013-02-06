issues = {}
window.fetchIssues = (repo='accounts', params)->
  params = $.extend({access_token: localStorage.getItem('token'), milestone: 4}, params)
  $.getJSON("https://api.github.com/repos/vitrue/#{repo}/issues?#{$.param(params)}&callback=?",(data)->
    json = {issues: data.data}
    for issue in json.issues 
      issue.first_label_color = issue.labels[0].color if issue.labels.length > 0 
    labels = []
    $('#labels').html('')
    $.each(data.data, (index,value)->
      console.log value
      $.each(value.labels, (index,label)->
        if label.name not in labels
          $('#labels').append(ich.label(label)) 
          labels.push(label.name)
      )
    )
    $('#issues-holder').html(ich.issues(json))
  ).then(sortIssues)
filterIssues = ->
  holder = $('#labels-holder')
  filtering_by_label = holder.hasClass('filtering-by-label')
  search_active = $("#search").val() != ''
  hide_em = $('#hide-filtered').is(':checked')

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
    if hide_em
      $(this).toggle(good)
    else if good
      $(this).css('-webkit-filter', '')
    else
      $(this).css('-webkit-filter', 'blur(4px) opacity(0.5)')

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

$(document).ready ->
  unless localStorage.getItem('token')
    params = {client_id: 'd96cd5d6ff897a568d80'}
    document.location.href = 'https://github.com/login/oauth/authorize'

  search = $('#search')
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

  fetchIssues()
