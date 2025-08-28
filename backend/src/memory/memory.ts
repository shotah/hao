type MemoryEvent =
  | { type: 'user_text'; text: string; ts: number }
  | { type: 'vision'; summary?: string; ts: number }
  | { type: 'image'; size: number; prompt: string | null; ts: number }
  | { type: 'system'; text: string; ts: number };

const byDevice = new Map<string, MemoryEvent[]>();

export const Memory = {
  append(deviceId: string, ev: MemoryEvent) {
    const arr = byDevice.get(deviceId) || [];
    arr.push(ev);
    byDevice.set(deviceId, arr);
  },
  list(deviceId: string): MemoryEvent[] {
    return byDevice.get(deviceId) || [];
  },
  setChecklist(deviceId: string, checklist: string[]) {
    const key = `${deviceId}:checklist`;
    (globalThis as any)[key] = checklist;
  },
  getChecklist(deviceId: string): string[] {
    const key = `${deviceId}:checklist`;
    return (globalThis as any)[key] || ["Drink water", "2-min stretch", "Get sunlight"];
  }
};
