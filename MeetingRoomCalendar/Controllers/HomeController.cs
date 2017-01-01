using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

// For more information on enabling MVC for empty projects, visit http://go.microsoft.com/fwlink/?LinkID=397860

namespace MeetingRoomCalendar.Controllers
{
    public class HomeController : Controller
    {
        private readonly AppSettings settings;
        public HomeController(IOptions<AppSettings> appSettings)
        {
            settings = appSettings.Value;
        }
        // GET: /<controller>/
        public IActionResult Index()
        {
            return View(settings);
        }

        public IActionResult Calendar(string id)
        {
            ViewData["MailBox"] = id;
            return View(settings);
        }
    }
}
