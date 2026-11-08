export function sayHi(user) {
  alert(`Hello ${user}`)
}

/**
 * This function converts a list of elements to options with proper html tags 
 * @param {Array} list_of_elements The list of elements to be converted into options
 * @returns {string} the list with <option value> tags attached
 */
export function jslist_to_html(list_of_elements) {
  html_to_add = ""
  for (let i = 0; i < list_of_elements.length; i++) {
    temp = `<option value='${list_of_elements[i]}'>${list_of_elements[i]}</option>`
    html_to_add += temp
  }
  return html_to_add
}

export function movePopup(event) {
  var customPopup = document.getElementById('customPopup');
  // move the customPopup
  customPopup.style.top = window.scrollY + event.clientY + "px";
  customPopup.style.left = window.scrollX + event.clientX + "px";
}

var clickCounter = 0
export function disappearPopup(event) {
  var customPopup = document.getElementById('customPopup');
  // move the customPopup
  customPopup.style.top = window.scrollY + event.clientY + "px";
  customPopup.style.left = window.scrollX + event.clientX + "px";
  // make it disappear
  if (clickCounter % 2 === 0) {
    customPopup.style.zIndex = -1
    customPopup.style.visibility = "hidden"
  }
  else {
    customPopup.style.zIndex = 1
    customPopup.style.visibility = "visible"
  }
  // increase clickCounter
  clickCounter += 1
}