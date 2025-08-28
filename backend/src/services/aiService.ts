// Placeholder AI service. Swap with real OpenAI calls later.
export async function handleCompanionReply(deviceId: string, text: string): Promise<string> {
  // Extremely simple intent handling for now
  const t = text.toLowerCase();
  if (t.includes('weather')) {
    return 'Weather: 72°F and clear (stub). I can wire a real API next.';
  }
  if (t.includes('remind')) {
    return 'Okay! I saved a reminder (stub). I will ping you at the right time.';
  }
  if (t.includes('hello') || t.includes('hi')) {
    return 'Hey! I'm here. Want to check off your morning routine?';
  }
  return `You said: "${text}". I’ll get smarter as we integrate real AI + memory.`;
}
