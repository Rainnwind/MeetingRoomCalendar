using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Exchange.WebServices.Data;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;
using System.Text.RegularExpressions;

namespace MeetingRoomCalendar.Controllers
{
    [Route("api/[controller]")]
    public class CalendarController : Controller
    {

        private readonly AppSettings settings;
        private readonly ILogger logger;
        public CalendarController(IOptions<AppSettings> appSettings, ILogger<CalendarController> logger)
        {
            settings = appSettings.Value;
            this.logger = logger;
        }

        private ExchangeService GetService(string mailName, out string email, out ActionResult errorResult)
        {
            email = $"{mailName}@{settings.MailDomain}";
            if (!settings.MeetingRoomMailboxes.Select(v => v.ToUpperInvariant()).Contains(mailName.ToUpperInvariant()))
            {
                errorResult = NotFound($"Mailbox {email} is not in MeetingRoomMailboxes");
                return null;
            }
            var service = new ExchangeService(ExchangeVersion.Exchange2013);
            service.UseDefaultCredentials = true;
            if (String.IsNullOrEmpty(settings.EwsUrl)) {
                try
                {
                    service.AutodiscoverUrl(email);
                }
                catch (Microsoft.Exchange.WebServices.Data.AutodiscoverLocalException e)
                {
                    errorResult = StatusCode(503, e.Message);
                    return null;
                }
                catch (Microsoft.Exchange.WebServices.Autodiscover.AutodiscoverRemoteException e)
                {
                    errorResult = NotFound(e.Error.Message);
                    return null;
                }
            }
            else
            {
                service.Url = new Uri(settings.EwsUrl); ;
            }
            errorResult = null;
            return service;
        }



        [HttpGet("{mailName}")]
        public ActionResult Get(string mailName, DateTime? from, DateTime? to)
        {

            if (!from.HasValue)
            {
                from = DateTime.Now;
            }
            if (!to.HasValue)
            {
                to = from.Value.Date.AddDays(1);
            }
            if (from.Value > to.Value)
            {
                return BadRequest($"Invalid appointments period {from.Value:s}-{to.Value:s}");
            }
            string email;
            ActionResult errorResult;
            var service = GetService(mailName, out email, out errorResult);
            if (service == null)
            {
                return errorResult;
            }
            var folder = Folder.Bind(
                service,
                new FolderId(WellKnownFolderName.Calendar, new Mailbox(email)),
                new PropertySet(BasePropertySet.FirstClassProperties));
            var name = service.ResolveName(email).First().Mailbox.Name;
            var cal = new Model.Calendar()
            {
                UniqueId = folder.Id.UniqueId,
                Owner = new Model.Mailbox()
                {
                    EMail = email,
                    Name = name
                },
                From = from.Value,
                To = to.Value,
                CanCreate = folder.EffectiveRights.HasFlag(EffectiveRights.CreateContents),
                CanDelete = folder.EffectiveRights.HasFlag(EffectiveRights.Modify),
                CanModify = folder.EffectiveRights.HasFlag(EffectiveRights.Delete),
                Appointments = service
                    .FindAppointments(folder.Id, new CalendarView(from.Value, to.Value))
                    .Select(a => ConvertAppointment(service, a.Id.UniqueId)).Where(a => a != null).ToArray()
            };
            return Ok(cal);
        }

        private Appointment GetAppointment(ExchangeService service, string id)
        {
            if (id == null)
            {
                return null;
            }
            try
            {
                return Appointment.Bind(
                    service,
                    id,
                    new PropertySet(BasePropertySet.FirstClassProperties)
                    {
                        RequestedBodyType = BodyType.Text
                    });
            }
            catch (ServiceResponseException)
            {
                return null;
            }
        }

        private Model.Appointment ConvertAppointment(ExchangeService service, string id)
        {
            return ConvertAppointment(GetAppointment(service, id));
        }

        private Model.Appointment ConvertAppointment(Appointment a)
        {
            if (a == null) return null;
            var res = new Model.Appointment()
            {
                UniqueId = a.Id.UniqueId,
                CanModify = a.EffectiveRights.HasFlag(EffectiveRights.Modify) && (settings.ModifyEnabledCategories.Length == 0 || settings.ModifyEnabledCategories.Any(a.Categories.Contains)),
                CanDelete = a.EffectiveRights.HasFlag(EffectiveRights.Delete) && (settings.DeleteEnabledCategories.Length == 0 || settings.DeleteEnabledCategories.Any(a.Categories.Contains)),
                Start = a.Start,
                End = a.End,
                IsAllDayEvent = a.IsAllDayEvent,
                IsBusy = a.LegacyFreeBusyStatus == LegacyFreeBusyStatus.Busy,
                Subject = a.Subject,
                Body = a.Body,
                Organizer = ConvertEMailAddressToMailbox(a.Organizer, a.Service),
                RequiredAttendees = a.RequiredAttendees.Select(ra => ConvertEMailAddressToMailbox(ra, a.Service)).ToArray(),//ra => new Model.Mailbox() { EMail = ra.Address, Name = ra.Name }).ToArray(),
                OptionalAttendees = a.OptionalAttendees.Select(oa => ConvertEMailAddressToMailbox(oa , a.Service)).ToArray(),//ra => new Model.Mailbox() { EMail = ra.Address, Name = ra.Name }).ToArray(),
                Categories = a.Categories.ToArray()
            };
            return res;
        }

        private Model.Mailbox ConvertEMailAddressToMailbox(EmailAddress m, ExchangeService service)
        {
            if (Regex.IsMatch(m.Name, @"^/O=[^/]*/OU=[^/]*"))
            {
                var alt = service.ResolveName(m.Address).FirstOrDefault()?.Mailbox;
                if (alt != null)
                {
                    m = alt;
                }
            }
            var res = new Model.Mailbox()
            {
                EMail = m.Address,
                Name = m.Name
            };
            if (Regex.IsMatch(res.Name, @"^/O=[^/]*/OU=[^/]*"))
            {
                res.Name = Regex.Replace(res.EMail, "^([^@]+)@.*$", @"$1");
            }
            return res;
        }

        private Appointment ConvertAppointment(Model.Appointment appointment, ExchangeService service)
        {
            var a = new Appointment(service);
            a.Start = appointment.Start;
            a.End = appointment.End;
            a.IsAllDayEvent = appointment.IsAllDayEvent;
            a.LegacyFreeBusyStatus = appointment.IsBusy ? LegacyFreeBusyStatus.Busy : LegacyFreeBusyStatus.Free;
            a.Subject = appointment.Subject;
            a.Body = appointment.Body;
            a.IsReminderSet = false;
            a.Categories = new StringList(appointment.Categories??new string[0]);
            return a;
        }

        [HttpGet("{mailName}/appointment/{id}")]
        public ActionResult GetAppointment(string mailName, string id)
        {
            string email;
            ActionResult errorResult;
            var service = GetService(mailName, out email, out errorResult);
            if (service == null)
            {
                return errorResult;
            }
            return Ok(ConvertAppointment(service, id));
        }

        [HttpPost("{mailName}/appointment")]
        public ActionResult PostAppointment(string mailName, [FromBody]Model.Appointment appointment)
        {
            if (appointment==null)
            {
                return BadRequest("No (valid) appointment was posted");
            }
            if (!String.IsNullOrEmpty(appointment.UniqueId))
            {
                return BadRequest("New appointment cannot have an id - use PUT to update existing appointments");
            }
            string email;
            ActionResult errorResult;
            var service = GetService(mailName, out email, out errorResult);
            if (service==null)
            {
                return errorResult;
            }
            var folder = Folder.Bind(
                service,
                new FolderId(WellKnownFolderName.Calendar, new Mailbox(email)),
                new PropertySet(BasePropertySet.FirstClassProperties));
            if (!folder.EffectiveRights.HasFlag(EffectiveRights.CreateContents))
            {
                return StatusCode(403, $"{System.Security.Principal.WindowsIdentity.GetCurrent().Name} has no create rights in the calendar of {email}");
            }
            if (settings.CreateEnabledCategories.Any() && !settings.CreateEnabledCategories.Any(appointment.Categories.Contains))
            {
                return StatusCode(403, "Create denied on category");
            }
            var a = ConvertAppointment(appointment, service);
            a.Save(folder.Id, SendInvitationsMode.SendToNone);
            return Ok(ConvertAppointment(service, a.Id.UniqueId));
        }

        [HttpPut("{mailName}/appointment")]
        public ActionResult PutAppointment(string mailName, [FromBody]Model.Appointment appointment)
        {
            if (appointment == null)
            {
                return BadRequest("No (valid) appointment was put");
            }
            if (String.IsNullOrEmpty(appointment.UniqueId))
            {
                return BadRequest("Existing appointment must have an id - use POST to add new appointments");
            }
            return StatusCode(501, "Appointment update with PUT yet not implemented");
        }

        [HttpDelete("{mailName}/appointment")]
        public ActionResult DeleteAppointment(string mailName, [FromBody]string id)
        {
            string email;
            ActionResult errorResult;
            var service = GetService(mailName, out email, out errorResult);
            if (service == null)
            {
                return errorResult;
            }
            var deletedAppointment = GetAppointment(service, id);
            if (deletedAppointment == null)
            {
                return NotFound($"Found no appointment in user {email}'s calendar with unique id {id}");
            }
            if (!deletedAppointment.EffectiveRights.HasFlag(EffectiveRights.Delete))
            {
                return StatusCode(403, "Delete appointment denied");
            }
            if (settings.DeleteEnabledCategories.Length > 0 && !settings.DeleteEnabledCategories.Any(deletedAppointment.Categories.Contains))
            {
                return StatusCode(403, "Delete appointment denied on category");
            }
            var expectedParentFolder = Folder.Bind(
                service,
                new FolderId(WellKnownFolderName.Calendar, new Mailbox(email)),
                new PropertySet(BasePropertySet.IdOnly));
            if (deletedAppointment.ParentFolderId.UniqueId != expectedParentFolder.Id.UniqueId)
            {
                return StatusCode(409, $"Appointment is not in user {email}'s calendar");
            }
            deletedAppointment.Delete(DeleteMode.HardDelete, SendCancellationsMode.SendToNone);
            return Ok(ConvertAppointment(deletedAppointment));
        }
    }
}
