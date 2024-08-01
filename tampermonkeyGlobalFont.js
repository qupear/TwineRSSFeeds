// ==UserScript==
// @name         Match Every Site
// @namespace    http://tampermonkey.net/
// @version      1.1
// @description  I will pop up on every site!!
// @author       You
// @match        *://*/*
// @grant        none
// ==/UserScript==

javascript:Array.prototype.forEach.call(document.getElementsByTagName("*"),
function(e){e.style.fontFamily ="aIosev"})
