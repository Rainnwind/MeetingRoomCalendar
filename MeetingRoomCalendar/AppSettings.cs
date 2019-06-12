using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MeetingRoomCalendar
{
    public class AppSettings
    {
        public string MailDomain { get; set; }
        public string EwsUrl { get; set; }
        public string[] MeetingRoomMailboxes { get; set; }
        public bool UseMailboxName { get; set; }
        public string[] DeleteEnabledCategories { get; set; }
        public string[] CreateEnabledCategories { get; set; }
        public string[] ModifyEnabledCategories { get; set; }
    }
}
