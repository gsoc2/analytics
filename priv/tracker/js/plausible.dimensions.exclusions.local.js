!function(){"use strict";var p=window.location,l=window.document,s=l.currentScript,u=s.getAttribute("data-api")||new URL(s.src).origin+"/api/event",w=s&&s.getAttribute("data-exclude").split(",");function c(t){console.warn("Ignoring Event: "+t)}function t(t,e){if(!(window._phantom||window.__nightmare||window.navigator.webdriver||window.Cypress)){try{if("true"===window.localStorage.plausible_ignore)return c("localStorage flag")}catch(t){}if(w)for(var i=0;i<w.length;i++)if("pageview"===t&&p.pathname.match(new RegExp("^"+w[i].trim().replace(/\*\*/g,".*").replace(/([^\.])\*/g,"$1[^\\s/]*")+"/?$")))return c("exclusion rule");var n={};n.n=t,n.u=p.href,n.d=s.getAttribute("data-domain"),n.r=l.referrer||null,n.w=window.innerWidth,e&&e.meta&&(n.m=JSON.stringify(e.meta)),e&&e.props&&(n.p=e.props);var a=s.getAttributeNames().filter(function(t){return"event-"===t.substring(0,6)}),r=n.p||{};a.forEach(function(t){var e=t.replace("event-",""),i=s.getAttribute(t);r[e]=r[e]||i}),n.p=r;var o=new XMLHttpRequest;o.open("POST",u,!0),o.setRequestHeader("Content-Type","text/plain"),o.send(JSON.stringify(n)),o.onreadystatechange=function(){4===o.readyState&&e&&e.callback&&e.callback()}}}var e=window.plausible&&window.plausible.q||[];window.plausible=t;for(var i,n=0;n<e.length;n++)t.apply(this,e[n]);function a(){i!==p.pathname&&(i=p.pathname,t("pageview"))}var r,o=window.history;o.pushState&&(r=o.pushState,o.pushState=function(){r.apply(this,arguments),a()},window.addEventListener("popstate",a)),"prerender"===l.visibilityState?l.addEventListener("visibilitychange",function(){i||"visible"!==l.visibilityState||a()}):a()}();