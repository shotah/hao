import cron from 'node-cron';

type Pusher = { toDevice: (deviceId: string, payload: any) => void };
type MemoryAPI = { getChecklist: (d: string) => string[], append: (d: string, ev: any) => void };

export function scheduleAll(Push: Pusher, Memory: MemoryAPI, deviceIds: string[]) {
  // Good morning at 8:00 local time
  cron.schedule('0 8 * * *', () => {
    deviceIds.forEach(did => {
      const checklist = Memory.getChecklist(did);
      Push.toDevice(did, { kind: 'morning', text: `Good morning! Here's your routine: ${checklist.join(', ')}` });
      Memory.append(did, { type: 'system', text: 'Morning ping sent', ts: Date.now() });
    });
  }, { timezone: process.env.TZ || 'America/Los_Angeles' });

  // Random check-in every 2 hours at minute 17
  cron.schedule('17 */2 * * *', () => {
    deviceIds.forEach(did => {
      Push.toDevice(did, { kind: 'checkin', text: 'How are you feeling? Want a quick stretch or a water break?' });
      Memory.append(did, { type: 'system', text: 'Check-in ping sent', ts: Date.now() });
    });
  }, { timezone: process.env.TZ || 'America/Los_Angeles' });
}
