// le_process.js — THE THIRD COMPOSER-SCORE OBJECT FOR THE ELECTRONICS: THE PROCESS BRICK, and the catalogue of effects it offers
// (the engine plan's parts 6 · 11; first built in the Decibel piece, 2026-10-05 — its PLAN 1.3 · RUNNING_LOG §103).
// A piece's composer page loads it with ONE tag, after le_objects.js —   <script src="/electronics/le_process.js"></script>
// — and names its key in the attach line (keys.process; `e` in the first piece). It is a MIXIN on LEObjects: that file knows
// only that 'elecProcess' is one of its models and hands this one the label, the panel, the redraw, the key and the tick.
//
//   midiModel 'elecProcess'   A STAGE OF A CHAIN.   elec: { source, out, label, effect, args, end, … , rendered }
//       A banked sample (source) put through ONE configuration of the engine's chain (sc/process.scd) and banked again under a
//       name of its own (out) — <root>~1, ~2, … : the root is the sample the chain began from. The next brick's source is this
//       brick's out: each stage is made FROM the one before, and every stage is kept ("I am sitting in a room").
//       RENDER (the panel's button) sends   /le/process   source · out · effect · args · end · … · id   and the engine renders it
//       OFFLINE and indexes it; this file waits for the row that carries its id, then the brick is as long as its sample.
//       Played through, a rendered brick sends exactly a plain return's message:   /le/play   name = out.
//       KEY: at the playhead — its source the selected brick's sample, else the nearest return or stage before the playhead.
//
//   THE CATALOGUE (EFFECTS, below) is the chain's stages, by name, each with the few dials that matter and the engine's own
//   control names under them: a brick's args are   { controlName: value }   — what the message carries. A stage is ALONE when
//   its mix is up and nothing else is; the JSON box takes ANY of the chain's controls, so two stages at once is a brick too.
//   HOW IT ENDS: shape — an envelope after the effect (attack · length · release · curve): the processed timbre with a struck
//   shape · tail — it rings out to floorDb under its own peak, or to capMs past the source. LEVEL: its peak as its source's
//   (match), then gainDb.
//
// Nothing in this file knows a piece. What it asks of LEObjects: MODELS.elecProcess · host · opts · index · row · zones · make ·
// is · say · redraw · loadIndex · _info. What it asks of the page: window.LE (le_msg.js).
(function () {
    'use strict';
    const L = window.LEObjects;
    if (!L) return;
    const r3 = (x) => Math.round(x * 1000) / 1000;
    const safe = (s) => String(s == null ? '' : s).replace(/[^A-Za-z0-9_~-]/g, '').slice(0, 64);   // a name is a file name (sc/bank.scd)
    const byName = (a, b) => String(a).localeCompare(String(b), undefined, { numeric: true });
    const D = (key, label, min, max, step, def, unit) => ({ key, label, min, max, step, def, unit: unit || '' });
    const O = (key, label, options, def) => ({ key, label, options, def });

    // PRESETS (§111, his ask) — starting points for an effect: a name and the dials it sets (merged onto the effect's defaults); the dials
    // stay editable after. Only the feedback has them so far; any row may carry `presets`.
    const FB_PRESETS = [
        { name: 'held note — a Hendrix sustain', args: { fbBloom: 0.8, fbHold: 4, fbDrive: 8, fbTone: 2500, fbPath: 8, fbClimb: 0.15, fbWobble: 0.2 } },
        { name: 'slow bloom — it rises out of the slap', args: { fbBloom: 3, fbHold: 6, fbDrive: 4, fbTone: 1800, fbPath: 10, fbClimb: 0, fbWobble: 0.1 } },
        { name: 'squeal — it climbs the harmonics', args: { fbBloom: 0.4, fbHold: 3, fbDrive: 12, fbTone: 4000, fbPath: 5, fbClimb: 0.8, fbWobble: 0.3 } },
        { name: 'power chord — E5, four strings', args: { fbBloom: 0.6, fbHold: 4, fbDrive: 10, fbTone: 3000, fbPath: 8, fbS1: 82.41, fbS2: 123.47, fbS3: 164.81, fbS4: 329.63, fbS5: 0, fbS6: 0 } },
        { name: 'found — no strings, the slap\'s own spectrum', args: { fbBloom: 1, fbHold: 3, fbDrive: 6, fbTone: 2500, fbPath: 12, fbClimb: 0.3, fbWobble: 0.4, fbS1: 0, fbS2: 0, fbS3: 0, fbS4: 0, fbS5: 0, fbS6: 0 } },
        { name: 'bark — short and hard', args: { fbBloom: 0.15, fbHold: 0.4, fbDrive: 15, fbTone: 3500, fbPath: 6, fbClimb: 0, fbWobble: 0 } },
    ];

    // THE CATALOGUE — the chain's stages in the order the chain runs them (sc/process.scd); `on` is what the stage needs besides its dials
    // Grown 2026-10-05 by audition (the Decibel piece's DEC-17 · §106): `override`, and after `drive` the pedals and the shredders — the
    // dials PROVISIONAL until he has heard each on a brick; the knobs are shaped after.
    const EFFECTS = [
        { key: 'none', label: 'none — the source as it is: clears the dials; a render is the source under the envelope', dials: [] },   // §107: his reset
        { key: 'tape', label: 'tape — speed and direction', dials: [D('rate', 'speed ×', 0.05, 8, 0.01, 0.5), O('rev', 'direction', [[0, 'forward'], [1, 'reversed']], 0)] },
        { key: 'noise', label: 'noise bed — follows the sample\'s envelope', dials: [D('noise', 'amount', 0, 1, 0.05, 0.5), D('noiseCut', 'cutoff', 200, 16000, 100, 8000, 'Hz')] },
        { key: 'override', label: 'buffer override — a mini-buffer repeated: a stutter, or a pitch (divisor ÷ forced buffer)', dials: [D('ovrMix', 'mix', 0, 1, 0.05, 1), D('ovrBuf', 'forced buffer', 10, 4000, 1, 250, 'ms'), D('ovrDiv', 'divisor', 1, 256, 1, 8), D('ovrSmooth', 'smoothing', 0, 0.5, 0.01, 0.1)] },
        { key: 'resonator', label: 'resonator bank — four ringing bands', dials: [D('resMix', 'mix', 0, 1, 0.05, 1), D('resDcy', 'decay', 0.02, 3, 0.02, 0.6, 's'), D('rlo', '110 Hz', 0, 1, 0.05, 0.5), D('rlomid', '440 Hz', 0, 1, 0.05, 0.5), D('rhimid', '1600 Hz', 0, 1, 0.05, 0.5), D('rhi', '5200 Hz', 0, 1, 0.05, 0.5)] },
        { key: 'cres', label: 'complex resonator — one ringing partial', dials: [D('cresMix', 'mix', 0, 1, 0.05, 1), D('cresFreq', 'pitch', 20, 8000, 1, 300, 'Hz'), D('cresDcy', 'decay', 0.01, 0.99, 0.01, 0.6)] },
        { key: 'drive', label: 'drive — six shapers', dials: [D('shapeMix', 'mix', 0, 1, 0.05, 1), O('driveType', 'shaper', [[0, 'tanh'], [1, 'sine'], [2, 'crossover'], [3, 'fold'], [4, 'bitcrush'], [5, 'disintegrate']], 0), D('drive', 'drive', 1, 40, 0.5, 8), D('driveArg', 'character', 0.05, 1, 0.05, 0.5)] },
        { key: 'overdrive', label: 'overdrive — a pedal, soft', dials: [D('odMix', 'mix', 0, 1, 0.05, 1), D('odDrive', 'drive', 1, 40, 0.5, 4), D('odTone', 'tone', 500, 8000, 50, 3000, 'Hz')] },
        { key: 'fuzz', label: 'fuzz — a pedal, hard and lopsided', dials: [D('fzMix', 'mix', 0, 1, 0.05, 1), D('fzGain', 'fuzz', 2, 200, 1, 30), D('fzBias', 'bias', -1, 1, 0.05, 0.3), D('fzTone', 'tone', 500, 8000, 50, 4000, 'Hz')] },
        { key: 'octave', label: 'octave fuzz — rectified, the octave above', dials: [D('ocMix', 'mix', 0, 1, 0.05, 1), D('ocOctave', 'octave', 0, 1, 0.05, 1), D('ocGain', 'fuzz', 2, 200, 1, 20), D('ocTone', 'tone', 500, 8000, 50, 4000, 'Hz')] },
        { key: 'cab', label: 'cabinet — a guitar speaker\'s voicing, after a pedal', dials: [D('cabMix', 'mix', 0, 1, 0.05, 1), D('cabLow', 'low cut', 40, 300, 5, 100, 'Hz'), D('cabHigh', 'high roll-off', 2000, 12000, 100, 4500, 'Hz'), D('cabPres', 'presence', -12, 12, 0.5, 3, 'dB')] },
        { key: 'feedback', label: 'feedback — the slap held to the amp: six strings bloom and sing', dials: [D('fbMix', 'mix', 0, 1, 0.05, 1), D('fbBloom', 'bloom', 0.05, 10, 0.05, 1, 's'), D('fbHold', 'hold', 0, 20, 0.1, 2, 's'), D('fbDrive', 'drive', 1, 40, 0.5, 6), D('fbTone', 'tone', 500, 8000, 50, 2500, 'Hz'), D('fbPath', 'path', 1, 50, 0.5, 8, 'ms'), D('fbClimb', 'climb', 0, 1, 0.05, 0), D('fbWobble', 'wobble', 0, 1, 0.05, 0), D('fbS1', 'string 1', 0, 2000, 0.01, 82.41, 'Hz'), D('fbS2', 'string 2', 0, 2000, 0.01, 110, 'Hz'), D('fbS3', 'string 3', 0, 2000, 0.01, 146.83, 'Hz'), D('fbS4', 'string 4', 0, 2000, 0.01, 196, 'Hz'), D('fbS5', 'string 5', 0, 2000, 0.01, 246.94, 'Hz'), D('fbS6', 'string 6', 0, 2000, 0.01, 329.63, 'Hz')], presets: FB_PRESETS },
        { key: 'crush', label: 'crush — bit depth and sample rate', dials: [D('crMix', 'mix', 0, 1, 0.05, 1), D('crBits', 'bits', 2, 16, 1, 8), D('crRate', 'rate', 500, 48000, 100, 12000, 'Hz')] },
        { key: 'cheby', label: 'cheby — harmonics by Chebyshev polynomials', dials: [D('chMix', 'mix', 0, 1, 0.05, 1), D('chDrive', 'drive', 0.1, 4, 0.1, 1), D('ch2', '2nd', 0, 1, 0.05, 0.5), D('ch3', '3rd', 0, 1, 0.05, 0.3), D('ch4', '4th', 0, 1, 0.05, 0), D('ch5', '5th', 0, 1, 0.05, 0.2)] },
        { key: 'squiz', label: 'squiz — chopped and squeezed up in pitch', dials: [D('sqMix', 'mix', 0, 1, 0.05, 1), D('sqRatio', 'ratio', 1, 16, 0.1, 2), D('sqChunks', 'chunks', 1, 32, 1, 1)] },
        { key: 'waveloss', label: 'waveloss — wave cycles dropped', dials: [D('wlMix', 'mix', 0, 1, 0.05, 1), D('wlDrop', 'drop', 0, 100, 1, 20), D('wlOf', 'of every', 1, 100, 1, 40), O('wlMode', 'which', [[1, 'the first ones'], [2, 'at random']], 2)] },
        { key: 'ring', label: 'ring modulation — a sine carrier', dials: [D('rmMix', 'mix', 0, 1, 0.05, 1), D('rmFreq', 'carrier', 20, 8000, 1, 300, 'Hz')] },
        { key: 'diode', label: 'diode ring modulation — the circuit, gritty', dials: [D('drmMix', 'mix', 0, 1, 0.05, 1), D('drmFreq', 'carrier', 10, 6000, 1, 180, 'Hz')] },
        { key: 'shift', label: 'frequency shift — detunes, inharmonic', dials: [D('fsMix', 'mix', 0, 1, 0.05, 1), D('fsHz', 'shift', -1200, 1200, 1, 120, 'Hz')] },
        { key: 'comb', label: 'comb — a delay that rings at a pitch', dials: [D('combMix', 'mix', 0, 1, 0.05, 1), D('combTime', 'delay', 0.002, 0.5, 0.001, 0.012, 's'), D('combFb', 'ring', 0.01, 4, 0.05, 0.8, 's')] },
        { key: 'filter', label: 'filter — four models', dials: [D('filtMix', 'mix', 0, 1, 0.05, 1), O('filtType', 'model', [[0, 'MoogFF'], [1, 'Moog ladder'], [2, 'LPF18'], [3, 'RLPFD']], 0), D('cut', 'cutoff', 80, 16000, 10, 1200, 'Hz'), D('res', 'resonance', 0, 3.9, 0.05, 0.5), D('filtDist', 'distortion', 0, 1, 0.05, 0.4), D('hpf', 'high-pass', 20, 2000, 5, 30, 'Hz')] },
        { key: 'string', label: 'string resonator — a plucked string', dials: [D('stresMix', 'mix', 0, 1, 0.05, 1), D('stresTime', 'delay', 0.0002, 0.05, 0.0001, 0.003, 's'), D('stresRes', 'resonance', 0, 0.99, 0.01, 0.9)] },
        { key: 'diffusion', label: 'diffusion — smears the attack, no tail', dials: [D('diffMix', 'mix', 0, 1, 0.05, 1), D('diffTime', 'time', 0.0005, 0.05, 0.0005, 0.02, 's'), D('diffGain', 'amount', 0, 0.9, 0.05, 0.6)] },
        { key: 'smear', label: 'smear — spectral blur', dials: [D('smear', 'bins', 0, 24, 1, 8)] },
        { key: 'gate', label: 'spectral gate — the loudest bins only', dials: [D('gate', 'threshold', 0, 60, 0.1, 2)] },
        { key: 'freeze', label: 'freeze — the spectrum, held', on: { freeze: 1 }, dials: [D('freezeAtMs', 'at', 0, 2000, 5, 60, 'ms'), D('smear', 'smear', 0, 24, 1, 0)] },
        { key: 'reverb', label: 'reverb — a room', dials: [D('revMix', 'mix', 0, 1, 0.05, 0.5), D('revTime', 'time', 0.1, 20, 0.1, 2, 's'), D('revDamp', 'damping', 0, 1, 0.05, 0.4), D('revRoom', 'room', 1, 90, 1, 22)] },
        { key: 'greyhole', label: 'Greyhole — a delay and a reverb at once', dials: [D('ghMix', 'mix', 0, 1, 0.05, 0.6), D('ghTime', 'delay', 0.01, 4, 0.01, 0.4, 's'), D('ghSize', 'size', 0.5, 5, 0.1, 1), D('ghFb', 'feedback', 0, 1, 0.05, 0.7), D('ghDiff', 'diffusion', 0, 1, 0.05, 0.7), D('ghDamp', 'damping', 0, 1, 0.05, 0.2)] },
        { key: 'jpverb', label: 'JPverb — a reverb with a decay per band', dials: [D('jpMix', 'mix', 0, 1, 0.05, 0.6), D('jpT60', 'time', 0.1, 20, 0.1, 2, 's'), D('jpSize', 'size', 0.5, 5, 0.1, 1.2), D('jpDamp', 'damping', 0, 1, 0.05, 0.3), D('jpLow', 'low ×', 0, 2, 0.05, 1), D('jpMid', 'mid ×', 0, 2, 0.05, 1), D('jpHigh', 'high ×', 0, 2, 0.05, 1)] },
    ];
    // how a render ends and how loud it is — a new brick's
    // THE HINTS (§108, his ask: "I hover the mouse and it tells me what it does and … the useful range") — by control name:
    // [what it does, the usual range]; the full range is read off the dial itself. Shown as the title of the label, the slider and the box.
    const HINTS = {
        _mix: ['how much of the effect: 0 is none, 1 is the effect alone', '1 for a stage of its own'],
        rate: ['tape speed: 2 is an octave up and half the length, 0.5 an octave down and twice the length', '0.25 … 2'],
        rev: ['the direction the sample is read'],
        noise: ['pink noise that follows the sample\'s own loudness — a breath under it', '0.1 … 0.5'],
        noiseCut: ['the noise is low-passed here: lower is darker', '2000 … 8000'],
        resDcy: ['how long the four bands ring after each sound', '0.2 … 1.5'],
        rlo: ['the band at 110 Hz: how loud it rings', '0 … 1'], rlomid: ['the band at 440 Hz: how loud it rings', '0 … 1'],
        rhimid: ['the band at 1600 Hz: how loud it rings', '0 … 1'], rhi: ['the band at 5200 Hz: how loud it rings', '0 … 1'],
        cresFreq: ['the pitch of the one ringing partial', '100 … 2000'],
        cresDcy: ['how long it rings: near 1 is almost endless', '0.5 … 0.95'],
        driveType: ['the shaper: tanh is soft · sine bends · crossover leaves a gap at zero · fold folds the wave back · bitcrush lowers the sample rate · disintegrate drops bits of the wave'],
        drive: ['gain into the shaper: more is harder, denser', '2 … 20'],
        driveArg: ['the shaper\'s character — it means something different per shaper: the fold\'s depth, the crush\'s rate, the gap\'s width', '0.2 … 0.8'],
        rmFreq: ['the carrier: the result is the sum and the difference of every partial with it — low is a tremolo, high is bells', '30 … 1000'],
        drmFreq: ['the diode ring\'s carrier: the same arithmetic, with grit', '30 … 800'],
        fsHz: ['every partial moved by this many Hz: the harmonics stop lining up — small is a chorus, large is metal', '−300 … 300'],
        combTime: ['the delay between the comb\'s teeth: the pitch is 1 ÷ delay — 0.012 s rings near 83 Hz, 0.002 s near 500 Hz', '0.002 … 0.03'],
        combFb: ['how long the comb rings, in seconds', '0.3 … 2'],
        filtType: ['the model: MoogFF and Moog ladder are round; LPF18 and RLPFD can distort (the distortion dial)'],
        cut: ['the cutoff: above it the sound is taken away', '200 … 5000'],
        res: ['resonance: a peak at the cutoff; near 3.9 it whistles', '0.3 … 2.5'],
        filtDist: ['the filter\'s own distortion (LPF18 and RLPFD only)', '0.2 … 0.8'],
        hpf: ['a high-pass after the filter: below it the sound is taken away', '20 … 200'],
        stresTime: ['the string\'s length as a delay: the pitch is 1 ÷ delay — 0.003 s is near 333 Hz', '0.001 … 0.01'],
        stresRes: ['how long the string rings: near 0.99 almost forever', '0.8 … 0.98'],
        diffTime: ['the size of the smear, in seconds — short blurs the attack, long is a small room with no tail', '0.005 … 0.03'],
        diffGain: ['how much is fed back through the smear', '0.4 … 0.8'],
        smear: ['the spectrum blurred across this many bins: the pitch goes, the colour stays', '4 … 12'],
        gate: ['only the bins this far above the rest survive: higher keeps less', '1 … 10'],
        freezeAtMs: ['the moment the spectrum is caught and held, from the sample\'s start', '20 … 200'],
        revTime: ['the reverb\'s decay, in seconds', '1 … 6'], revDamp: ['the high end dies faster as this rises', '0.2 … 0.7'], revRoom: ['the room\'s size', '10 … 60'],
        ghTime: ['the delay before each echo, in seconds', '0.05 … 1'], ghSize: ['the space\'s size', '0.5 … 3'],
        ghFb: ['how much comes round again: near 1 is endless', '0.5 … 0.9'], ghDiff: ['how smeared each echo is', '0.5 … 0.9'],
        ghDamp: ['the high end dies faster as this rises', '0.1 … 0.5'],
        jpT60: ['the decay to −60 dB, in seconds', '1 … 8'], jpSize: ['the space\'s size', '0.8 … 3'], jpDamp: ['the high end dies faster as this rises', '0.2 … 0.6'],
        jpLow: ['the low band\'s decay, times this: 2 is twice as long', '0.5 … 1.5'], jpMid: ['the mid band\'s decay, times this', '0.5 … 1.5'], jpHigh: ['the high band\'s decay, times this', '0.5 … 1.5'],
        ovrBuf: ['the forced buffer: how often a new slice is taken, in ms', '50 … 500'],
        ovrDiv: ['mini-buffers per forced buffer — the slice kept is 1 ÷ this of it; the pitch is divisor ÷ buffer ms × 1000 Hz: 24 ÷ 120 ms is 200 Hz', '4 … 64'],
        ovrSmooth: ['the share of each slice crossfaded at the join: 0 clicks, 0.5 is soft', '0.05 … 0.25'],
        odDrive: ['gain into the soft clip: the mids first, the lows less', '2 … 15'],
        odTone: ['the tone after the clip: lower is darker', '1500 … 5000'],
        fzGain: ['gain into the hard clip: everything flattens', '20 … 100'],
        fzBias: ['an offset before the clip, so one side clips first: 0 is even, far from 0 is gated and spitty', '0.1 … 0.5'],
        fzTone: ['the tone after the fuzz: lower is darker', '2000 … 6000'],
        ocOctave: ['how much is rectified: 1 is the octave above, 0 is a plain fuzz', '0.5 … 1'],
        ocGain: ['gain into the hard clip', '10 … 60'], ocTone: ['the tone after the fuzz: lower is darker', '2000 … 6000'],
        cabLow: ['below this the speaker gives nothing', '60 … 150'], cabHigh: ['above this the speaker rolls off, steeply', '3000 … 6000'],
        cabPres: ['the presence at 2.5 kHz, in dB: cut for warmth, boost for bite', '0 … 6'],
        fbBloom: ['how long the tone takes to grow from nothing to full — the loop gain is set from it', '0.3 … 3'],
        fbHold: ['how long it sings before the loop is broken; then the strings ring down (1.5 s)', '1 … 8'],
        fbDrive: ['the amp\'s clipping: the ceiling the bloom meets — more is thicker and buzzier', '3 … 15'],
        fbTone: ['the speaker\'s colour inside the loop: it steers which harmonics win — low is dark, high is a squeal', '1500 … 5000'],
        fbPath: ['the distance to the amp, as a delay: it chooses which modes can bloom, and is itself a comb at 1 ÷ path', '3 … 20'],
        fbClimb: ['the colour and the path move up over the hold: the feedback climbs the harmonics, as a guitar held closer does', '0 … 0.7'],
        fbWobble: ['the player\'s hand: the path drifts slowly, the tone wavers between harmonics', '0 … 0.5'],
        fbS1: ['a string in the loop, in Hz; 0 is no string — all six at 0 and the slap\'s own spectrum takes off (E2 82.41)', '60 … 700'],
        fbS2: ['a string in the loop, in Hz; 0 is no string (A2 110)', '60 … 700'], fbS3: ['a string in the loop, in Hz; 0 is no string (D3 146.83)', '60 … 700'],
        fbS4: ['a string in the loop, in Hz; 0 is no string (G3 196)', '60 … 700'], fbS5: ['a string in the loop, in Hz; 0 is no string (B3 246.94)', '60 … 700'],
        fbS6: ['a string in the loop, in Hz; 0 is no string (E4 329.63)', '60 … 700'],
        crBits: ['the bit depth: 16 is clean, 8 is grainy, 4 is a buzz, 2 is a square', '3 … 10'],
        crRate: ['the sample rate: below the sound\'s highest partial, mirror tones appear', '2000 … 16000'],
        chDrive: ['gain into the polynomials: past 1 the wave clips', '0.5 … 1.5'],
        ch2: ['the 2nd harmonic: an octave up', '0 … 0.6'], ch3: ['the 3rd harmonic: an octave and a fifth up', '0 … 0.6'],
        ch4: ['the 4th harmonic: two octaves up', '0 … 0.4'], ch5: ['the 5th harmonic: two octaves and a third up', '0 … 0.4'],
        sqRatio: ['the pitch ratio: 2 is an octave up, each chunk squeezed to half its length', '1.5 … 4'],
        sqChunks: ['zero crossings per chunk: more is smoother, fewer is rougher', '1 … 8'],
        wlDrop: ['how many wave cycles are dropped', '10 … 30'], wlOf: ['out of how many', '20 … 60'],
        wlMode: ['which cycles go: the first ones of each group, or random ones'],
    };
    const hintOf = (d) => {
        const h = HINTS[d.key] || (/Mix$/.test(d.key) ? HINTS._mix : null);
        return (h ? h[0] : d.label) + (d.options ? '' : ' — ' + d.min + ' … ' + d.max + (d.unit ? ' ' + d.unit : '')) + (h && h[1] ? ' · usually ' + h[1] : '');
    };

    // THE ENDINGS (§111, his ask): shape — his envelope · tail — the ring-out · perc — SuperCollider's Env.perc (a fast rise, a fall, both on
    // curve −4; the sandbox's grains use it) · the Roads grain envelopes (Microsound): gauss (a bell) · quasi (Gaussian sides, a flat middle) ·
    // tri (a triangle) · expodec (instant, an exponential fall to −60 dB) · rexpodec (its mirror: an exponential rise, then cut).
    // Each new one has a STANDARD length, set the moment it is picked; the length box changes it. The engine draws them (sc/process.scd processDone).
    const ENDS = [
        ['shape', 'shape — an envelope; its length is the object\'s', null],
        ['tail', 'tail — it rings out', null],
        ['perc', 'perc — SuperCollider\'s Env.perc: a fast rise, a fall on curve −4', { durMs: 1010, atkMs: 10 }],
        ['gauss', 'gauss — Roads: a bell', { durMs: 500 }],
        ['quasi', 'quasi-gauss — Roads: Gaussian sides, a flat middle', { durMs: 800 }],
        ['tri', 'triangle — Roads: up to the middle, then down', { durMs: 400 }],
        ['expodec', 'expodec — Roads: instant, then an exponential fall', { durMs: 600 }],
        ['rexpodec', 'rexpodec — Roads: an exponential rise, then cut', { durMs: 600 }],
    ];
    const END_STD = Object.fromEntries(ENDS.map(([k, , s]) => [k, s]));
    const isEnd = (k) => ENDS.some(([x]) => x === k);
    const END = { end: 'shape', atkMs: 2, durMs: 600, relMs: 600, curve: -4, floorDb: -60, capMs: 8000, gainDb: 0, match: 1 };
    const RANGE = { atkMs: [0, 10000], durMs: [10, 120000], relMs: [0, 120000], curve: [-12, 12], floorDb: [-120, -6], capMs: [100, 60000], gainDb: [-60, 24], match: [0, 1] };
    const clamp = (k, v) => Math.max(RANGE[k][0], Math.min(RANGE[k][1], v));

    Object.assign(L, {
        EFFECTS, PROCESS_END: END,
        effect(key) { return EFFECTS.find((f) => f.key === key) || null; },
        effectDefaults(key) { const f = this.effect(key), a = {}; if (f) for (const d of f.dials) a[d.key] = d.def; return a; },
        // every control the engine gets: what turns the stage on, then the brick's own
        processArgs(e) { const f = this.effect(e.effect); return Object.assign({}, f && f.on, e.args || {}); },
        // §111 (his randomizer): a dial may be a RANGE [lo, hi] — the brick keeps the range; at every Render a value is DRAWN from it
        // (uniform, rounded to the dial's step) and the message carries the number; the engine's row records what was drawn.
        isRange(v) { return Array.isArray(v) && v.length === 2 && Number.isFinite(+v[0]) && Number.isFinite(+v[1]); },
        // §113: THE SHELF — the settings the composer has kept (the piece's; the server's route `opts.shelfUrl`, '/api/candidates' by default:
        // GET the rows · POST one more). Picked from the panel, a row's setting is applied whole; the "keep → shelf" button posts this brick's.
        loadShelf() {
            const url = (this.opts && this.opts.shelfUrl) || '/api/candidates', file = (this.opts && this.opts.shelfFile) || '/bank/candidates.json';
            const rows = (j) => (Array.isArray(j) ? j : (j && Array.isArray(j.rows) ? j.rows : null));
            return fetch(url, { cache: 'no-store' }).then((r) => (r.ok ? r.json() : Promise.reject(new Error('no route')))).then((j) => rows(j) || Promise.reject(new Error('no rows')))
                .catch(() => fetch(file, { cache: 'no-store' }).then((r) => r.json()).then((j) => rows(j) || []))   // a server started before the route: the file itself (static) — the menu works, "keep" waits for the restart
                .then((list) => { this._shelf = list; return list; })
                .catch(() => { this._shelf = []; return this._shelf; });
        },
        keep(zone, remark) {
            const e = zone.elec, s = this.processSettings(e), row = this.row(e.out), setting = {};
            for (const k of ['effect', 'args', 'end', 'atkMs', 'durMs', 'relMs', 'curve', 'floorDb', 'capMs', 'gainDb', 'match', 'label']) if (s[k] !== undefined) setting[k] = s[k];
            const body = { setting, heardOn: e.source, out: e.out, label: e.label || '', effect: e.effect, render: row ? Math.round(row.lengthMs) + ' ms · peak ' + row.peakDb + ' dB' : 'not rendered', remark: remark || '' };
            const url = (this.opts && this.opts.shelfUrl) || '/api/candidates';
            return fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }).then((r) => r.json())
                .then((j) => {
                    if (!j || !j.success || !j.row) throw new Error((j && j.error) || 'the server said no');
                    this._shelf = Array.isArray(j.rows) ? j.rows : this._shelf;
                    this.say('kept as candidate ' + j.row.n + ' · ' + j.row.effect + ' on ' + j.row.heardOn);
                    if (this.host.selectedObject === zone) this.host.showPropertyPanel();
                    return j.row;
                })
                .catch((err) => { this.say('NOT kept: ' + err.message + ' — a score server started before this build has no shelf route: restart it'); return null; });
        },
        // §112 (his global randomizer): one dial drawn at random — across its whole range, or within its USUAL range (the hint's);
        // log-uniform where the slider is log; an option dial picks one of its options; rounded to the step
        rollDial(d, usual) {
            if (d.options) return +d.options[Math.floor(Math.random() * d.options.length)][0];
            let lo = d.min, hi = d.max;
            const h = HINTS[d.key];
            if (usual && h && h[1]) { const m = String(h[1]).replace(/−/g, '-').match(/(-?\d+(?:\.\d+)?)\s*…\s*(-?\d+(?:\.\d+)?)/); if (m) { lo = Math.max(d.min, +m[1]); hi = Math.min(d.max, +m[2]); } }
            if (!(hi > lo)) { lo = d.min; hi = d.max; }
            const logish = lo > 0 && hi / lo >= 50;
            let v = logish ? lo * Math.pow(hi / lo, Math.random()) : lo + Math.random() * (hi - lo);
            if (d.step > 0) v = +(Math.round(v / d.step) * d.step).toFixed(Math.max(0, -Math.floor(Math.log10(d.step) + 1e-9)));
            return Math.min(hi, Math.max(lo, v));
        },
        drawArgs(e, a) {
            const f = this.effect(e.effect), drawn = [];
            for (const k of Object.keys(a)) {
                if (!this.isRange(a[k])) continue;
                const lo = Math.min(+a[k][0], +a[k][1]), hi = Math.max(+a[k][0], +a[k][1]), d = f && f.dials.find((x) => x.key === k), step = d && d.step > 0 ? d.step : 0;
                let v = lo + Math.random() * (hi - lo);
                if (step) v = +(Math.round(v / step) * step).toFixed(Math.max(0, -Math.floor(Math.log10(step) + 1e-9)));
                a[k] = v; drawn.push((d ? d.label : k) + ' ' + v);
            }
            return drawn;
        },
        rootOf(name) { return String(name || '').split('~')[0]; },
        nextOut(source, skip) {
            const root = this.rootOf(source) || 'sample', used = new Set(this.index.map((r) => r.name));
            for (const z of this.zones('elecProcess')) if (z !== skip && z.elec && z.elec.out) used.add(z.elec.out);
            for (let n = 1; n < 10000; n++) if (!used.has(root + '~' + n)) return root + '~' + n;
            return root + '~' + Date.now();
        },
        // the brick's settings as one string: has anything changed since its render?
        processSig(e) {
            const a = this.processArgs(e), keys = Object.keys(a).sort();
            return JSON.stringify([e.source, e.effect, keys.map((k) => [k, a[k]]), e.end, e.end === 'tail' ? [+e.floorDb, +e.capMs] : [+e.atkMs, +e.durMs, +e.relMs, +e.curve], +e.gainDb, +e.match]);
        },
        // what the message carries (the engine's field names)
        processMessage(zone, id) {
            const e = zone.elec, a = this.processArgs(e);
            this._drawnFor = this._drawnFor || {}; this._drawnFor[safe(e.out)] = this.drawArgs(e, a);   // the ranges, drawn for THIS render
            const args = Object.keys(a).filter((k) => /^[A-Za-z][A-Za-z0-9]*$/.test(k) && Number.isFinite(+a[k])).map((k) => k + ':' + (+a[k])).join(',');
            const m = { id, source: safe(e.source), out: safe(e.out), effect: String(e.effect || '').slice(0, 40), args, end: isEnd(e.end) ? e.end : 'shape', gainDb: +e.gainDb || 0, match: +e.match > 0 ? 1 : 0 };
            if (m.end !== 'tail') Object.assign(m, { atkMs: +e.atkMs || 0, durMs: +e.durMs || END.durMs, relMs: +e.relMs || 0, curve: +e.curve || 0 });
            else Object.assign(m, { floorDb: +e.floorDb || END.floorDb, capMs: +e.capMs || END.capMs });
            return m;
        },
        // none: not in the bank · changed: its settings since the render · older: its source was made after it · ok
        processState(zone) {
            const e = zone.elec, row = this.row(e.out), src = this.row(e.source);
            if (!row) return 'none';
            if (e.rendered && e.rendered.sig && e.rendered.sig !== this.processSig(e)) return 'changed';
            if (src && src.captured && row.captured && String(src.captured) > String(row.captured)) return 'older';
            return 'ok';
        },
        processLabel(zone) {
            const e = zone.elec, st = this.processState(zone);
            return this.MODELS.elecProcess.sign + ' ' + (e.label ? e.label + ' · ' : '') + (e.out || '?') + ' = ' + (e.effect || '?') + ' ← ' + (e.source || '?')
                + (st === 'none' ? ' — not rendered' : st === 'changed' ? ' — changed: render again' : st === 'older' ? ' — its source is newer: render again' : '');
        },
        // a rendered brick is as long as its sample
        processRedraw(zone) {
            const row = this.row(zone.elec && zone.elec.out);
            if (row && row.lengthMs > 0) zone.endTime = r3(zone.startTime + row.lengthMs / 1000);
        },

        // ---- the gesture --------------------------------------------------------------------------------------------------
        addProcess() {
            const h = this.host, o = this.opts, sel = h.selectedObject, t = Math.max(0, h.getTimeAtPlayhead());
            const nameOf = (z) => (z.midiModel === 'elecProcess' ? z.elec.out : z.elec.name);
            const fromSel = this.is(sel) && sel.elec && nameOf(sel) ? sel : null;
            let layer = fromSel ? fromSel.layer : h.activeLane;
            if (layer == null || layer < 0 || layer >= o.lanes) { this.say('a process brick goes on a player\'s lane — click the lane first'); return null; }
            // its source: the selected brick's sample · else the latest return or stage before the playhead (this lane's first) · else the index's first
            const before = this.zones().filter((z) => z.elec && (z.midiModel === 'elecProcess' || (z.midiModel === 'elecPlay' && !z.elec.behaviour)) && nameOf(z) && z.startTime <= t)
                .sort((a, b) => b.startTime - a.startTime);
            const src = fromSel || before.find((z) => z.layer === layer) || before[0] || null;
            const source = src ? nameOf(src) : (this.index[0] ? this.index[0].name : '');
            if (!source) { this.say('nothing to process yet — capture a sample first (' + String(o.keys.open).toUpperCase() + ' over a note)'); return null; }
            if (src) layer = src.layer;
            const row = this.row(source), len = row && row.lengthMs > 0 ? row.lengthMs : o.openMs, effect = 'comb';
            const elec = Object.assign({ source, out: this.nextOut(source), label: '', effect, args: this.effectDefaults(effect), rendered: null }, END);
            const z = this.make('elecProcess', layer, t, t + len / 1000, elec);
            this.say('process brick ' + elec.out + ' ← ' + source + ' on ' + o.laneLabel(layer) + ' — its effect and its dials are in the panel; Render makes it');
            this.loadIndex();
            return z;
        },
        // a new name for the brick's sample: the bricks that play it or are made from it follow
        renameOut(zone, now) {
            const e = zone.elec, was = e.out;
            e.out = now; e.rendered = null;
            for (const z of this.zones()) {
                if (z === zone || !z.elec) continue;
                if (z.midiModel === 'elecProcess' && z.elec.source === was) z.elec.source = now;
                if (z.midiModel === 'elecPlay' && z.elec.name === was) z.elec.name = now;
            }
        },
        setSource(zone, source) {
            const e = zone.elec;
            e.source = source;
            if (this.rootOf(source) !== this.rootOf(e.out)) this.renameOut(zone, this.nextOut(source, zone));   // another sample's chain: a name of that chain
        },
        processSettings(e) {
            const o = {};
            for (const k of ['source', 'out', 'label', 'effect', 'args', 'end', 'atkMs', 'durMs', 'relMs', 'curve', 'floorDb', 'capMs', 'gainDb', 'match']) o[k] = e[k];
            return o;
        },
        // the whole setting written at once (the panel's box): what is not a setting is left out, what is out of range is brought in
        processApply(zone, o) {
            const e = zone.elec;
            if (!o || typeof o !== 'object') return;
            if (typeof o.effect === 'string') e.effect = o.effect.slice(0, 40);
            if (o.args && typeof o.args === 'object') {
                e.args = {};
                for (const k of Object.keys(o.args)) {
                    if (!/^[A-Za-z][A-Za-z0-9]*$/.test(k)) continue;
                    if (this.isRange(o.args[k])) e.args[k] = [+o.args[k][0], +o.args[k][1]];   // a range: drawn at each render
                    else if (Number.isFinite(+o.args[k])) e.args[k] = +o.args[k];
                }
            }
            if (isEnd(o.end)) e.end = o.end;
            for (const k of Object.keys(RANGE)) if (o[k] != null && Number.isFinite(+o[k])) e[k] = clamp(k, +o[k]);
            if (typeof o.label === 'string') e.label = o.label.trim().slice(0, 40);
            if (typeof o.source === 'string' && safe(o.source) && safe(o.source) !== e.source) this.setSource(zone, safe(o.source));
            if (typeof o.out === 'string' && safe(o.out) && safe(o.out) !== e.out && safe(o.out) !== e.source) this.renameOut(zone, safe(o.out));
        },

        // ---- the panel ----------------------------------------------------------------------------------------------------
        processPanel(zone, sec, ui) {
            const e = zone.elec, { el, rowEl, note, commit } = ui, doc = sec.ownerDocument, small = 'font-size:11px';
            for (const k of Object.keys(END)) if (e[k] === undefined) e[k] = END[k];
            if (!e.args || typeof e.args !== 'object') e.args = {};
            const fx = this.effect(e.effect);
            const tiny = (t) => el('span', { textContent: t, style: 'font-size:10px;color:#888;white-space:nowrap' });
            const pair = (...kids) => el('span', { style: 'display:inline-flex;align-items:center;gap:4px;flex-wrap:wrap;' + small }, kids);
            const btn = (t, fn, title) => { const b = el('button', { type: 'button', textContent: t, title: title || '', style: small }); b.addEventListener('click', fn); return b; };
            const num = (obj, key, min, max, step, width, title) => {
                const n = el('input', { type: 'number', value: obj[key] == null ? '' : String(obj[key]), min: String(min), max: String(max), step: String(step), style: 'width:' + (width || 64) + 'px', title: title || '' });
                n.addEventListener('change', () => { const v = +n.value; if (n.value === '' || !Number.isFinite(v)) { n.value = obj[key] == null ? '' : String(obj[key]); return; } commit(() => { obj[key] = Math.max(min, Math.min(max, v)); }); });
                return n;
            };
            const pick = (value, options, write) => {
                const s = el('select', { style: 'max-width:230px' });
                for (const [v, t] of options) s.appendChild(el('option', { value: String(v), textContent: t, selected: String(value) === String(v) }));
                s.addEventListener('change', () => { s.blur(); commit(() => write(s.value)); });
                return s;
            };
            const text = (value, write, width) => { const n = el('input', { type: 'text', value: value || '', style: 'width:' + (width || 150) + 'px' }); n.addEventListener('change', () => write(n)); return n; };
            // §108: a SLIDER beside each dial's box — while it is dragged the box follows and nothing is rebuilt; at its release ONE commit
            // (one undo step, the brick redrawn). Frequencies and times (a range of 50× or more) slide on a LOG scale, so the low end has room.
            const slider = (obj, key, d, box) => {
                const logish = d.min > 0 && d.max / d.min >= 50;
                const dec = Math.max(0, -Math.floor(Math.log10(d.step) + 1e-9));
                const toT = (v) => Math.round(logish ? 1000 * Math.log(v / d.min) / Math.log(d.max / d.min) : 1000 * (v - d.min) / (d.max - d.min));
                const fromT = (t) => { const v = logish ? d.min * Math.pow(d.max / d.min, t / 1000) : d.min + (d.max - d.min) * t / 1000; return +Math.min(d.max, Math.max(d.min, Math.round(v / d.step) * d.step)).toFixed(dec); };
                const now = Math.min(d.max, Math.max(d.min, Number.isFinite(+obj[key]) ? +obj[key] : d.def));
                const s = el('input', { type: 'range', min: '0', max: '1000', step: '1', value: String(toT(now)), style: 'flex:1 1 60px;min-width:50px;max-width:110px;vertical-align:middle;margin:0', title: hintOf(d) });   // it shrinks before the row wraps (§113)
                const before = obj[key];
                s.addEventListener('input', () => { const v = fromT(+s.value); obj[key] = v; box.value = String(v); });
                s.addEventListener('change', () => { const v = fromT(+s.value); obj[key] = before; commit(() => { obj[key] = v; }); });
                return s;
            };

            // THE SOURCE — any sample of the bank, or a stage placed and not yet rendered
            const srcs = this.index.map((r) => r.name).filter((n) => n !== e.out).sort(byName).map((n) => {
                const r = this.row(n);
                return [n, n + ' · ' + Math.round(r.lengthMs) + ' ms' + (r.kind === 'processed' ? ' · ' + (r.effect || 'processed') : '')];
            });
            for (const z of this.zones('elecProcess')) { const n = z.elec && z.elec.out; if (z !== zone && n && !this.row(n) && !srcs.some(([x]) => x === n)) srcs.push([n, n + ' — not rendered yet']); }
            if (!srcs.some(([n]) => n === e.source)) srcs.unshift([e.source || '', (e.source || '?') + ' — not in the bank']);
            sec.appendChild(rowEl('Source', pick(e.source, srcs, (v) => this.setSource(zone, v))));
            sec.appendChild(rowEl('Name', text(e.out, (n) => {
                const now = safe(n.value);
                if (!now || now === e.out || now === e.source) { n.value = e.out || ''; return; }
                commit(() => this.renameOut(zone, now));
            })));
            sec.appendChild(rowEl('Label', text(e.label, (n) => commit(() => { e.label = String(n.value || '').trim().slice(0, 40); }))));

            // THE EFFECT and its dials
            const fxs = EFFECTS.map((f) => [f.key, f.label]);
            if (!fx) fxs.unshift([e.effect || '', (e.effect || '?') + ' — not in the catalogue (its controls are in the box below)']);
            sec.appendChild(rowEl('Effect', pick(e.effect, fxs, (v) => { e.effect = v; e.args = this.effectDefaults(v); })));
            if (fx && fx.presets) {   // §111: a starting point — sets this effect's dials (onto its defaults); they stay editable
                const ps = pick('', [['', '— a starting point —']].concat(fx.presets.map((p, i) => [String(i), p.name])),
                    (v) => { const p = fx.presets[+v]; if (p) { e.args = Object.assign(this.effectDefaults(fx.key), p.args); if (p.end && isEnd(p.end)) Object.assign(e, { end: p.end }, END_STD[p.end] || {}); } });
                ps.title = 'a preset sets every dial of this effect at once; turn them after as you like';
                sec.appendChild(rowEl('Preset', ps));
            }
            // §113: THE SHELF — the settings he has kept; picking one applies it whole (effect · dials · ending); the source stays
            if (this._shelf === undefined) { this._shelf = null; this.loadShelf().then(() => { if (this.host.selectedObject === zone) this.host.showPropertyPanel(); }); }
            if (this._shelf && this._shelf.length) {
                const sh = pick('', [['', '— the shelf: ' + this._shelf.length + ' kept —']].concat(this._shelf.map((r) => [String(r.n), r.n + ' · ' + r.effect + (r.remark ? ' — ' + r.remark : '') + ' · on ' + r.heardOn])),
                    (v) => { const r = this._shelf.find((x) => String(x.n) === v); if (r && r.setting) this.processApply(zone, r.setting); });
                sh.title = 'a setting you kept (docs/CANDIDATES.md) — its effect, dials and ending applied whole to this brick; the source stays';
                sec.appendChild(rowEl('Shelf', sh));
            }
            if (fx) {
                for (const d of fx.dials) {
                    if (e.args[d.key] === undefined) e.args[d.key] = d.def;
                    const hint = hintOf(d);
                    let control;
                    if (d.options) { control = pick(e.args[d.key], d.options, (v) => { e.args[d.key] = +v; }); control.title = hint; }
                    else if (this.isRange(e.args[d.key])) {   // §111: a range — two boxes; a value is drawn between them at every Render
                        const r = e.args[d.key];
                        control = pair(num(r, 0, d.min, d.max, d.step, 58, 'the low end of the range'), tiny('…'), num(r, 1, d.min, d.max, d.step, 58, 'the high end of the range'), tiny(d.unit + ' · drawn at each render'),
                            btn('=', () => commit(() => { e.args[d.key] = +((Math.min(+r[0], +r[1]) + Math.max(+r[0], +r[1])) / 2).toFixed(4); }), 'back to one value: the middle of the range'));
                    } else {
                        const box = num(e.args, d.key, d.min, d.max, d.step, 64, hint), v = +e.args[d.key];
                        const logish = d.min > 0 && d.max / d.min >= 50, lo = logish ? v / 2 : v - (d.max - d.min) / 4, hi = logish ? v * 2 : v + (d.max - d.min) / 4;
                        control = pair(slider(e.args, d.key, d, box), box, tiny(d.unit),
                            btn('⚄', () => commit(() => { e.args[d.key] = [Math.max(d.min, +lo.toFixed(4)), Math.min(d.max, +hi.toFixed(4))]; }), 'make it a RANGE: a value is drawn between two ends at every Render'));
                    }
                    control.style.flexWrap = 'nowrap';   // §113: the ⚄ button stays on the dial's line (it wrapped under the slider on rows with a unit)
                    const row = rowEl(d.label, control);
                    if (row.firstChild) row.firstChild.title = hint;   // the label too: hover anywhere on the row
                    sec.appendChild(row);
                }
                if (fx.dials.some((d) => !/Mix$/.test(d.key))) {   // §112: the global randomizer — every dial but the mix (and the ranges, which draw themselves)
                    const roll = (usual) => commit(() => { for (const d of fx.dials) { if (/Mix$/.test(d.key) || this.isRange(e.args[d.key])) continue; e.args[d.key] = this.rollDial(d, usual); } });
                    sec.appendChild(rowEl('', pair(
                        btn('⚄ all', () => roll(false), 'every dial of this effect drawn at random across its WHOLE range — the mix and any range dial left alone'),
                        btn('⚄ usual', () => roll(true), 'every dial drawn at random within its USUAL range (the one the hover hint names) — the mix and any range dial left alone'))));
                }
                const more = Object.keys(e.args).filter((k) => !fx.dials.some((d) => d.key === k));
                if (more.length) sec.appendChild(note('also set, from the box below: ' + more.map((k) => k + ' ' + e.args[k]).join(' · ')));
            }

            // HOW IT ENDS · HOW LOUD
            const endPick = pick(e.end, ENDS.map(([k, t]) => [k, t]), (v) => { e.end = v; if (END_STD[v]) Object.assign(e, END_STD[v]); });   // a new envelope brings its standard length
            endPick.title = 'how the render ends: shape is your envelope · tail rings out to the floor · perc and the Roads envelopes are fixed curves over a length — picked, each sets its standard length; the box changes it';
            sec.appendChild(rowEl('Ends by', endPick));
            if (e.end === 'shape') {
                sec.appendChild(rowEl('', pair(tiny('attack'), num(e, 'atkMs', 0, 10000, 1, 52, 'the rise from silence, in ms — 0 … 10000 · usually 1 … 30'), tiny('length'), num(e, 'durMs', 10, 120000, 10, 64, 'the whole object\'s length, in ms — 10 … 120000; the release is inside it'), tiny('ms'))));
                sec.appendChild(rowEl('', pair(tiny('release'), num(e, 'relMs', 0, 120000, 10, 64, 'the fall at the end, in ms — 0 … the length; as long as the length = a struck shape'), tiny('ms · curve'), num(e, 'curve', -12, 12, 0.5, 52, 'the shape of the fall: −4 falls fast first (a struck sound), 0 is a straight line, above 0 holds then drops — −12 … 12'))));
                sec.appendChild(note('a release as long as the length = a struck shape, falling from the attack · curve −4 falls fast first, 0 is a straight line'));
            } else if (e.end === 'tail') {
                sec.appendChild(rowEl('', pair(tiny('until'), num(e, 'floorDb', -120, -6, 1, 52, 'the tail ends where it falls this far under its own peak — −120 … −6 · usually −60'), tiny('dB under its peak · at most'), num(e, 'capMs', 100, 60000, 100, 64, 'if it never falls that far (a freeze), it is cut and faded this long past the source — 100 … 60000 ms'), tiny('ms past the source'))));
            } else {
                const kids = [tiny('length'), num(e, 'durMs', 10, 120000, 10, 64, 'the whole object\'s length, in ms — 10 … 120000; the standard was set when the envelope was picked (' + (END_STD[e.end] ? END_STD[e.end].durMs : '') + ')'), tiny('ms')];
                if (e.end === 'perc') kids.unshift(tiny('attack'), num(e, 'atkMs', 0, 10000, 1, 52, 'the rise, in ms — Env.perc\'s standard is 10'));
                sec.appendChild(rowEl('', pair(...kids)));
            }
            const match = el('input', { type: 'checkbox', checked: +e.match > 0, style: 'margin:0 3px 0 0;vertical-align:middle' });
            match.addEventListener('change', () => commit(() => { e.match = match.checked ? 1 : 0; }));
            const matchLabel = el('label', { style: small }, [match]);
            matchLabel.appendChild(doc.createTextNode('peak as its source\'s'));
            matchLabel.title = 'ticked: the render\'s peak is set to its source\'s, so a chain neither fades nor runs hot · unticked: as rendered';
            sec.appendChild(rowEl('Level', pair(matchLabel, tiny('then'), num(e, 'gainDb', -60, 24, 0.5, 52, 'then this much on top, in dB — −60 … 24'), tiny('dB'))));

            // RENDER · LISTEN
            sec.appendChild(rowEl('', pair(
                btn('Render', () => this.render(zone), 'the engine puts the source through the effect, offline, and banks the result under the name'),
                btn('▶ hear it', () => this.audition(e.out), 'the rendered sample, now'),
                btn('▶ its source', () => this.audition(e.source), 'the sample it is made from, now'),
                btn('keep → shelf', () => { const r = window.prompt('a remark for the shelf (optional)', ''); if (r !== null) this.keep(zone, r); }, 'adds this brick\'s setting to the shelf — the Shelf menu and docs/CANDIDATES.md (§113)'))));
            const st = this.processState(zone), row = this.row(e.out), info = this._info['p' + zone.id];
            if (info) sec.appendChild(note(info));
            sec.appendChild(note(row ? 'in the bank: ' + Math.round(row.lengthMs) + ' ms · peak ' + row.peakDb + ' dB · made ' + String(row.captured || '').replace('T', ' ')
                + (row.effect ? ' · ' + row.effect + ' ← ' + (row.source || '?') : '')
                : 'not rendered yet — Render, with the engine up; then it plays where the brick is'));
            if (st === 'changed') sec.appendChild(note('its settings have changed since that render — Render again'));
            if (st === 'older') sec.appendChild(note('its source was made after it — Render again to follow it'));

            // THE WHOLE SETTING, as text
            const box = el('textarea', { value: JSON.stringify(this.processSettings(e), null, 1), rows: 7, spellcheck: false, style: 'width:100%;box-sizing:border-box;font:10px/1.3 monospace' });
            sec.appendChild(el('div', { className: 'pp-row' }, [box]));
            sec.appendChild(rowEl('', pair(btn('Apply', () => {
                let o = null;
                try { o = JSON.parse(box.value); } catch (err) { this.say('the box is not valid JSON: ' + err.message); return; }
                commit(() => this.processApply(zone, o));
            }, 'the whole setting, as written in the box'), tiny('the whole setting — args takes any control of the chain'))));
        },

        // ---- the render: one message, then the bank's index until the row with this render's id is there ---------------------
        render(zone) {
            const h = this.host, e = zone.elec, key = 'p' + zone.id;
            const tell = (t) => { this._info[key] = t; this.say(t); if (h.selectedObject === zone) h.showPropertyPanel(); };
            this._rendering = this._rendering || {};
            if (this._rendering[key]) return this._rendering[key];
            if (!window.LE) { tell('NOT rendered: this page has no road to the engine (le_msg.js)'); return Promise.resolve(null); }
            if (!safe(e.source) || !safe(e.out) || safe(e.source) === safe(e.out)) { tell('NOT rendered: a source and a name of its own are needed'); return Promise.resolve(null); }
            const id = safe(String(zone.id) + '-' + Date.now().toString(36)), sig = this.processSig(e), started = Date.now();
            tell('rendering ' + e.out + ' ← ' + e.source + ' through ' + e.effect + ' …');
            const p = LE.send('process', this.processMessage(zone, id)).then((ans) => {
                if (!ans || !ans.ok) throw new Error('the score server did not take the message');
                return new Promise((resolve, reject) => {
                    const poll = () => this.loadIndex().then(() => {
                        const row = this.row(e.out);
                        if (row && row.openingId === id) return resolve(row);
                        if (Date.now() - started > 20000) return reject(new Error('no answer in 20 s — is the engine up, and started since the process brick was built? Its window says what it did.'));
                        setTimeout(poll, 400);
                    });
                    setTimeout(poll, 500);
                });
            }).then((row) => {
                e.rendered = { lengthMs: row.lengthMs, peakDb: row.peakDb, when: row.captured, sig };
                zone.endTime = r3(zone.startTime + row.lengthMs / 1000);
                h.markDirty();
                this.redraw();
                const drawn = (this._drawnFor || {})[safe(e.out)] || [];
                tell('rendered ' + e.out + ' — ' + Math.round(row.lengthMs) + ' ms · peak ' + row.peakDb + ' dB' + (drawn.length ? ' · drew ' + drawn.join(', ') : ''));
                return row;
            }).catch((err) => { tell('NOT rendered: ' + err.message); return null; })
                .then((r) => { delete this._rendering[key]; return r; });
            this._rendering[key] = p;
            return p;
        },
        // a sample, now — the engine plays it at once (the same message a return sends)
        audition(name) {
            if (!window.LE || !name) return;
            if (!this.row(name)) { this.say(name + ' is not in the bank yet'); return; }
            LE.send('play', { name: safe(name), id: 'audition', lane: -1, t: 0, dueMs: 0 });
            this.say('▶ ' + name);
        },
        // played through: a rendered stage is a return of its own sample
        processFire(host, z, at, dueMs) {
            const e = z.elec;
            if (!this.row(e.out)) { this.say('process brick ' + (e.out || '?') + ': not rendered — nothing is played'); return; }
            LE.send('play', { name: safe(e.out), id: String(z.id), lane: z.layer, t: r3(at), dueMs });
        },
    });
})();
