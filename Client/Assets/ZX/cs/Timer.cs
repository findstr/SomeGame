using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ZX
{
    class Timer {
        struct Event {
            public long time;
            public long session;
        };
        private long clock = 0;
        private long session = 0;
        private List<Event> events = new List<Event>();
        public long TimeOut(int ms) {
            long s = session + 1;
            long t = ms + clock;
            session = s;
            events.Add(new Event{ time = t, session = s });
            return s;
        }

        public void Update(int delta, List<long> expire) {
            clock += delta;
            for (int i = events.Count - 1; i >= 0; i--) {
                Event e = events[i];
                if (e.time <= clock) {
                    expire.Add(e.session); 
                    events.RemoveAt(i);
                }
            }
        }
    }
}
