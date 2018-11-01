(function() {
  var SESSION_ID_COOKIE = "_nsid";
  var SESSION_ID_COOKIE_MAX_AGE = 1800;
  var UNIQUE_ID_COOKIE = "_nuid";
  var UNIQUE_ID_COOKIE_MAX_AGE = 3600 * 24 * 30;

  var queue = window.nemea.q || [];
  var commands = {};

  function generateId(size) {
    size = (size || 64) / 2;

    var time = +new Date();
    var id = "";
    for (var i = 0; i < size; i++) {
      id += (time * Math.random()).toString(36).slice(-2);
    }

    return id;
  }

  function parseCookies() {
    var cookies = {};
    var pair_re = /([^=]+)=([^;]+);?/g;

    var matches;
    while ((matches = pair_re.exec(document.cookie)) !== null) {
      var name = decodeURIComponent(matches[1].trim());
      var value = decodeURIComponent(matches[2].trim());
      cookies[name] = value;
    }

    return cookies;
  }

  function setCookie(name, value, options) {
    options = options || {};
    options.path = options.path || "/";
    options.samesite = options.samesite || "strict";
    options["max-age"] = options["max-age"] || SESSION_ID_COOKIE_MAX_AGE;

    var cookie = encodeURIComponent(name) + "=" + encodeURIComponent(value);
    for (var prop in options) {
      cookie += ";" + prop;
      if (options[prop] !== null) {
        cookie += "=" + options[prop];
      }
    }

    document.cookie = cookie;
  }

  function normalizeURL(url) {
    var anchor = document.createElement("a");
    anchor.href = url;
    return anchor.href + "";
  }

  function collectData() {
    var cookies = parseCookies();
    var sessionId = cookies[SESSION_ID_COOKIE] || generateId();
    setCookie(SESSION_ID_COOKIE, sessionId);

    var uniqueId = cookies[UNIQUE_ID_COOKIE] || generateId();
    setCookie(UNIQUE_ID_COOKIE, uniqueId, {
      "max-age": UNIQUE_ID_COOKIE_MAX_AGE
    });

    var referrer = document.referrer && normalizeURL(document.referrer);
    var location = window.location.href + "";
    var links = document.getElementsByTagName("link");
    for (var i = 0; i < links.length; i++) {
      var link = links[i];
      if (
        link.getAttribute("rel") === "canonical" &&
        link.hasAttribute("href")
      ) {
        location = normalizeURL(link.getAttribute("href"));
        break;
      }
    }

    return {
      sid: sessionId,
      uid: uniqueId,
      loc: location,
      ref: referrer
    };
  }

  commands.view = function() {
    if (navigator.doNotTrack) {
      return;
    }

    var script = document.getElementById("nemea");
    var trackURL = normalizeURL(script.src.replace("track.js", "track"));
    var data = collectData();

    var params = [];
    for (var name in data) {
      params.push(
        encodeURIComponent(name) + "=" + encodeURIComponent(data[name])
      );
    }

    if (trackURL.indexOf("?") != trackURL.length - 1) {
      trackURL += "?";
    }
    trackURL += params.join("&");

    var img = document.createElement("img");
    img.src = trackURL;
    img.onload = function() {
      document.body.removeChild(img);
    };

    document.body.appendChild(img);
  };

  for (var i = 0; i < queue.length; i++) {
    var call = Array.prototype.slice.call(queue[i]);
    var command = call.shift();
    commands[command] && commands[command].apply(commands);
  }
})();
