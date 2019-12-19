var x = $("#location_status");
var location_request = true;
function showPosition(position) {
  x.text("Got Location ... Finding closest station ...");
  $.get("/agencies/"+window.agency_id+"/closest.json", {latitude: position.coords.latitude, longitude: position.coords.longitude}, function(route_stop) {
    x.text("Found closest station: "+route_stop.name);
    if( !location_request ){
      return;
    }
    $('#from-station').val(route_stop.name);
    $('#from-station').trigger("chosen:updated");
    fetch_departures();
  }, "json");
}
function errorCallback(code) {
  x.text("Sorry we couldn't find your location. Please select a station:");
}

if (navigator.geolocation) {
  x.text("Getting Location ...");
  var location_timeout = setTimeout("errorCallback(0)", 10000);

  navigator.geolocation.getCurrentPosition(function(position) {
    clearTimeout(location_timeout);
    showPosition(position);
  }, function(error) {
    clearTimeout(location_timeout);
    errorCallback(error.code);
  }, {
    enableHighAccuracy: true,
    timeout: 10000,
    maximumAge: 0
  });
} else {
  // Fallback for no geolocation
  errorCallback(0);
}
function fetch_departures() {
  console.log("fetch");
  newstop = $('#from-station').val();
  if (!newstop) {return};
  $.get(window.agency_id+'/departures.js',{stop_name: newstop});
}
$( document ).ready(function() {
  var angle = 0;
  $('#from-station').on('change', function(event) {
    console.log("selected");
    location_request = false;
    fetch_departures();
  });
  $('#from-station').chosen({});
  $('#refresh-button').on('click', function(event) {
    angle += 360;
    $(this).rotate({ animateTo: angle});
    fetch_departures();
  });
});
