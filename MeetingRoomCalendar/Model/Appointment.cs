using System;
using System.Collections.Generic;
using System.Runtime.Serialization;

namespace MeetingRoomCalendar.Model
{
    public class Appointment
    {
        public string UniqueId { get; set; }

        public string UniqueIdHash { get { return $"A{(UniqueId??"").GetHashCode()}".Replace("-", "N"); } }

        public bool CanModify { get; set; }

        public bool CanDelete { get; set; }

        public DateTime Start { get; set; }

        public DateTime End { get; set; }

        public bool IsAllDayEvent { get; set; }

        public bool IsBusy { get; set; }

        public string Subject { get; set; }

        public string Body { get; set; }

        public Mailbox Organizer { get; set; }

        public ICollection<Mailbox> RequiredAttendees { get; set; }

        public ICollection<Mailbox> OptionalAttendees { get; set; }

        public ICollection<string> Categories { get; set; }
    }
}