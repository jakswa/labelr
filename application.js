// Generated by CoffeeScript 1.4.0
(function() {
  var filterIssues, getURLParameter, issues, redirectToOauth, sortIssues,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  issues = {};

  getURLParameter = function(name, params) {
    if (params == null) {
      params = location.search;
    }
    return decodeURIComponent((new RegExp("[?|&]" + name + "=([^&;]+?)(&|##|;|$)").exec(params) || [null, ""])[1].replace(/\+/g, '%20')) || null;
  };

  window.fetchIssues = function(repo, params) {
    if (repo == null) {
      repo = 'accounts';
    }
    params = $.extend({
      access_token: localStorage.getItem('token'),
      milestone: 5
    }, params);
    return $.getJSON("https://api.github.com/repos/vitrue/" + repo + "/issues?" + ($.param(params)) + "&callback=?", function(data) {
      var issue, json, labels, _i, _len, _ref;
      json = {
        issues: data.data
      };
      _ref = json.issues;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        issue = _ref[_i];
        if (issue.labels.length > 0) {
          issue.first_label_color = issue.labels[0].color;
        }
      }
      labels = [];
      $('#labels').html('');
      $.each(data.data, function(index, value) {
        if ("Bad credentials" === value) {
          localStorage.setItem("bad_token", true);
          redirectToOauth();
          return;
        }
        console.log(value);
        return $.each(value.labels, function(index, label) {
          var _ref1;
          if (_ref1 = label.name, __indexOf.call(labels, _ref1) < 0) {
            $('#labels').append(ich.label(label));
            return labels.push(label.name);
          }
        });
      });
      return $('#issues-holder').html(ich.issues(json));
    }).then(sortIssues);
  };

  redirectToOauth = function() {
    return document.location.href = "https://github.com/login/oauth/authorize?client_id=d96cd5d6ff897a568d80&scope=repo";
  };

  filterIssues = function() {
    var active_names, filtering_by_label, holder, search_active;
    holder = $('#labels-holder');
    filtering_by_label = holder.hasClass('filtering-by-label');
    search_active = $("#search").val() !== '';
    active_names = [];
    holder.find('li.active').each(function() {
      return active_names.push($(this).data('label-name'));
    });
    issues = $('#issues > li');
    return issues.each(function() {
      var good, issue;
      good = !filtering_by_label;
      issue = $(this);
      $(this).find('li.label').each(function() {
        var _ref;
        if (filtering_by_label && (_ref = $(this).data('label-name'), __indexOf.call(active_names, _ref) >= 0)) {
          return good = true;
        }
      });
      if (search_active && !issue.html().match(new RegExp($('#search').val(), 'i'))) {
        good = false;
      }
      return $(this).toggle(good);
    });
  };

  sortIssues = function(ev) {
    var bottom, top;
    top = $("#top-sort").val();
    bottom = $("#bottom-sort").val();
    issues = $('#issues > li');
    return issues.each(function() {
      var down, issue, up;
      issue = $(this);
      up = false;
      down = false;
      $(this).find('li.label').each(function() {
        if ($(this).data('label-name') === top) {
          up = true;
        }
        if ($(this).data('label-name') === bottom) {
          return down = true;
        }
      });
      if (up) {
        issue.remove();
        return $('#issues').prepend(issue);
      } else if (down) {
        issue.remove();
        return $('#issues').append(issue);
      }
    });
  };

  $(document).ready(function() {
    var code, search;
    search = $('#search');
    code = getURLParameter("code");
    search.keyup(function(ev) {
      return filterIssues();
    });
    $('#app').on('click', 'li.label', function(ev) {
      var actives, holder, name, removing, selector, target_label;
      ev.stopPropagation();
      name = $(ev.currentTarget).data('label-name');
      if (ev.shiftKey) {
        $('#top-sort').val(name);
        sortIssues();
        return;
      } else if (ev.altKey) {
        $('#bottom-sort').val(name);
        sortIssues();
        return;
      }
      holder = $('#labels-holder');
      selector = "li[data-label-name='" + name + "']";
      target_label = holder.find(selector);
      removing = target_label.is('.active');
      actives = holder.find('li.active');
      if (!(ev.ctrlKey || (actives.length === 1 && removing))) {
        actives.removeClass('active');
      }
      target_label.toggleClass('active');
      holder.toggleClass('filtering-by-label', holder.has('.active').length !== 0);
      return filterIssues();
    });
    $('#clear-labels').click(function() {
      $('#labels-holder').removeClass('filtering-by-label').find('li.active').removeClass('active');
      return filterIssues();
    });
    $('#top-sort, #bottom-sort').keyup(sortIssues);
    if (localStorage.getItem("token") && !localStorage.getItem("bad_token")) {
      localStorage.removeItem("bad_token");
      return fetchIssues();
    } else if (code) {
      return $.post("http://goauth.jake.dev.cloud.vitrue.com/oauth", {
        code: code
      }, function(data) {
        var access_token;
        if (access_token = getURLParameter("access_token", "?" + data)) {
          localStorage.setItem("token", access_token);
          return fetchIssues();
        } else {
          return console.log("Well that didn't work... " + data);
        }
      });
    } else {
      return redirectToOauth();
    }
  });

}).call(this);