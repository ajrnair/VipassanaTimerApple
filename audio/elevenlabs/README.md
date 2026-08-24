# ElevenLabs voice-sample handoff (v1 — superseded)

> **Superseded.** The scripts and timings for the guided mode now live in
> [`../v2/`](../v2/README.md), with revised scripts, two audience tracks, corrected timing, and a
> cue manifest anchored to the app's session timeline. This folder is kept as the v1 record of the
> original voice-casting samples.

Generate these as voice-casting samples for a possible future guided mode. The current timer remains
silent apart from its gongs.

## Recommended starting setup

1. Open **Text to Speech** in ElevenLabs.
2. Choose **Eleven Multilingual v2**. It is the steadier choice for calm, consistent narration; the
   more expressive v3 model can sound performative for this material.
3. Choose a natural adult voice with an unforced accent. A calm Indian-English voice is welcome.
4. Start with these voice settings:

   - Stability: **65**
   - Similarity: **75**
   - Style exaggeration: **0**
   - Speaker Boost: **On**
   - Speed: **0.90**

5. Paste only the contents of one `.txt` file at a time. The files contain no stage directions that
   might accidentally be spoken.
6. Generate two takes if convenient. Keep the delivery that sounds most like a clear human teacher,
   not a meditation advertisement.

These values are a starting point, not a magic preset. If the result is theatrical or inconsistent,
raise Stability slightly. If it becomes flat or synthetic, lower Stability slightly. Keep Style at
zero.

## Performance direction

- Grounded, clear, warm, and matter-of-fact.
- Calm without becoming breathy, sleepy, whispered, devotional, or ASMR-like.
- Do not imitate a guru, announcer, therapist, or luxury-wellness advertisement.
- Use a natural speaking voice with clean consonants and restrained melody.
- Let sentences land. Avoid exaggerated emphasis on words such as “observe,” “sensations,” or
  “moment.”
- Aim for roughly **85–95 spoken words per minute**, excluding the planned silences.
- No music, bowls, ambience, reverb, or processing. Voice only.

## Pauses and assembly

Do not type labels such as `[pause 4 seconds]` into Text to Speech. Generate the spoken copy cleanly;
we can insert exact digital silence afterward. If you assemble the pieces in ElevenLabs Studio,
follow [timing-sheet.md](timing-sheet.md).

## Files to return

Preferred export is mono WAV at 48 kHz / 24-bit PCM. If your plan does not offer that export, send
the highest-quality download available and do not convert it yourself.

| Sample | Preferred filename | Optional second take |
|---|---|---|
| Arrival | `guide-arrival.wav` | `guide-arrival-take-2.wav` |
| Breath to sensation | `guide-breath-to-sensation.wav` | `guide-breath-to-sensation-take-2.wav` |
| Closing | `guide-closing.wav` | `guide-closing-take-2.wav` |

Leave levels and loudness untouched. I will trim, add exact pauses, normalize conservatively, and
prepare the final app assets after you return the samples.

## Current ElevenLabs references

- [Text to Speech product guide](https://elevenlabs.io/docs/eleven-creative/playground/text-to-speech)
- [Model overview](https://elevenlabs.io/docs/overview/models)
