using System;
using System.Collections.Generic;

namespace MeetingRoomCalendar.Model
{
    public class Calendar
    {
        public string UniqueId { get; set; }

        public Mailbox Owner { get; set; }

        public DateTime From { get; set; }

        public DateTime To { get; set; }

        public bool CanCreate { get; set; }

        public bool CanModify { get; set; }

        public bool CanDelete { get; set; }

        public ICollection<Appointment> Appointments { get; set; }

    }
}