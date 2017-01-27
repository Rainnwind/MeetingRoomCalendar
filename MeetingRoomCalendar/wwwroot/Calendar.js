var calendar = null;
var latestUpdateMinute = -1;
loadCalendar();
setInterval(loadCalendar, 60000);
setInterval(updateTimeEct, 500);

function updateTimeEct() {
    $("#time").text(getTimeFormatted(new Date(), true));
    var curMin = new Date().getMinutes()
    if (latestUpdateMinute != curMin) {
        updateForms();
        latestUpdateMinute = curMin;
    }
    
}

function getDateFormatted(date) {
    return date.toISOString().slice(0, 10);
}

function getTimeFormatted(date, includeSeconds) {
    includeSeconds = typeof includeSeconds !== 'undefined' ? includeSeconds : false;
    if (includeSeconds) {
        return date.toTimeString().slice(0, 8);
    }
    else {
        return date.toTimeString().slice(0, 5);
    }
}

function getDateTimeFormatted(date, includeSeconds) {
    return getDateFormatted(date) + " " + getTimeFormatted(date, includeSeconds);
}

function getActiveAppointments() {
    var res = [];
    if (calendar) {
        for (var i in calendar.appointments) {
            var a = calendar.appointments[i];
            var start = new Date(a.start);
            var end = new Date(a.end);
            if (start < Date.now() && Date.now() < end && a.isBusy) {
                res.push(a);
            }
        }
    }
    return res;
}

function displayCalendar() {
    if (calendar) {
        $("title").text(calendar.owner.name);
        $("h1.title").text(calendar.owner.name);
        tbody = $("table#calendar > tbody").empty();
        var from = new Date(calendar.from);
        var to = new Date(calendar.to);
        noAppointments = true;
        for (var i in calendar.appointments) {
            var a = calendar.appointments[i];
            var start = new Date(a.start);
            var end = new Date(a.end);
            if (start < to && from < end) {
                noAppointments = false;
                if (start < from) {
                    start = from;
                }
                if (end >= to) {
                    end = to;
                }
                var tr = $("<tr/>").attr("id", "APP" + i);
                if (a.isAllDayEvent) {
                    tr.append($("<td colspan='2' class='text-center'/>").text("Hele dagen"));
                }
                else {
                    tr
                        .append($("<td class='date'/>").text(getTimeFormatted(start)))
                        .append($("<td class='date'/>").text(getTimeFormatted(end)));
                }
                var deleteButton = $("<button id='" + a.uniqueIdHash + "' type='button' class='btn btn-sm' onclick='deleteMeeting(\"" + a.uniqueId + "\", \"" + a.uniqueIdHash + "\")'/>")
                    .text("Slet");
                if (!a.canDelete) {
                    deleteButton.attr("disabled", "disabled");
                }
                tr
                    .append($("<td/>").text(a.subject))
                    .append($("<td/>").text(a.organizer.name))
                    .append($("<td class='text-right'/>").append(deleteButton));
                tbody.append(tr);
            }
        };
        if (noAppointments) {
            tbody.append($("<tr><td colspan='5' class='text-center'>Ingen begivenheder i dag</td></th>"));
        }
    }
}

function displayFailure(jqXHR) {
    $("#update_status").text("Opdatering fejlede " + getDateTimeFormatted(new Date(), true)).append($("<br/>"));
    if (jqXHR.status === 0) {
        $("#update_status").append("Intet svar");
    }
    else {
        $("#update_status").append("Status " + jqXHR.status + " " + jqXHR.statusText);
        if (jqXHR.responseText) {
            $("#update_status").append($("<br/>")).append(jqXHR.responseText);
        }
    }
    $("#update_status").addClass("alert-danger");
}

function loadCalendar() {
    $("#reload_button").attr("disabled", "disabled");
    $("#update_status").text("Opdaterer ...")
    $("#update_status").removeClass("alert-danger");
    $()
    $.getJSON("/api/calendar/" + calendarMailbox).done(function (cal) {
        calendar = cal;
        displayCalendar();
        $("#update_status").empty();
        $("#latest_update").text("Seneste opdatering " + getDateTimeFormatted(new Date(), true));
        updateForms();
    }).fail(displayFailure).always(function () { $("#reload_button").removeAttr("disabled"); });
}

function updateForms() {
    var noActiveApp = true;
    var now = new Date();
    $("tr.table-active").removeClass("table-active");
    if (calendar) {
        for (var i in calendar.appointments) {
            var start = new Date(calendar.appointments[i].start);
            var end = new Date(calendar.appointments[i].end);
            if (start < now && now < end && calendar.appointments[i].isBusy) {
                $("#APP" + i).addClass("table-active");
                noActiveApp = false;
            }
        }
    }
    if (noActiveApp) {
        $("table#calendar").removeClass("alert-danger");
    }
    else {
        $("table#calendar").addClass("alert-danger");
    }
    if (calendar && calendar.canCreate && noActiveApp) {
        showNewMeetingForm();
    }
    else {
        hideNewMeetingForm();
    }
}

function enableNewMeetingForm() {
    $("#new_meeting_duration, #new_meeting_create").removeAttr("disabled");
}

function disableNewMeetingForm() {
    $("#new_meeting_duration, #new_meeting_create").attr("disabled", "disabled");
}

function hideNewMeetingForm() {
    $("#new_meeting").addClass("hidden");
    disableNewMeetingForm();
}

function showNewMeetingForm() {

    $("#new_meeting").removeClass("hidden");
    enableNewMeetingForm();
}

function createNewMeeting() {
    $("#new_meeting_status").text("Tilføjer ad-hoc møde");
    $("#new_meeting_status").removeClass("alert-danger");
    disableNewMeetingForm(false);
    var start = new Date();
    start.setMinutes(parseInt(start.getMinutes() / 15) * 15);
    start.setSeconds(0);
    start.setMilliseconds(0);
    newAppointment = {
        start: start,
        end: new Date(start.getTime() + $("#new_meeting_duration").val() * 60000),
        subject: "Ad-hoc møde",
        isBusy: true,
        isAllDayEvent: false,
        organizer: calendar.owner,
        categories: ["ADHOC"]
    }
    $.ajax({
        method: "POST",
        url: "/api/calendar/" + calendarMailbox + "/appointment",
        data: JSON.stringify(newAppointment),
        contentType: "application/json; charset=UTF-8"
    }).done(function () {
        loadCalendar();
        $("#new_meeting_status").empty();
        $("#new_meeting_status").removeClass("alert-danger");
    }).fail(function (jqXHR) {
        $("#new_meeting_status").text("Status " + jqXHR.status + " " + jqXHR.statusText);
        if (jqXHR.responseText) {
            $("#new_meeting_status").append($("<br/>")).append(jqXHR.responseText);
        }
        $("#new_meeting_status").addClass("alert-danger");
    });
}

function deleteMeeting(uniqueId, buttonId) {
    var button = $("#" + buttonId);
    button.attr("disabled", "disabled");
    $.ajax({
        method: "DELETE",
        url: "/api/calendar/" + calendarMailbox + "/appointment",
        data: JSON.stringify(uniqueId),
        dataType: "json",
        contentType: "application/json; charset=UTF-8"
    }).done(function () {
        loadCalendar();
    }).fail(function (jqXHR) {
        button.after($("<p class='alert-danger'/>").text("Could not delete: " + jqXHR.status));
    });
}
