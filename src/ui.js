/*
 * SFZ Player Module UI
 *
 * Uses shared sound generator UI base.
 * Bank switching (Shift+L/R) handled by base using 'instrument_index' param.
 */

/* Shared utilities - absolute path for module location independence */
import { createSoundGeneratorUI } from '/data/UserData/move-anything/shared/sound_generator_ui.mjs';

/* Create the UI - SFZ uses 'instrument_index' for bank switching */
const ui = createSoundGeneratorUI({
    moduleName: 'SFZ',
    bankParamName: 'instrument_index',
    showPolyphony: true,
    showOctave: true,
});

/* Export required callbacks */
globalThis.init = ui.init;
globalThis.tick = ui.tick;
globalThis.onMidiMessageInternal = ui.onMidiMessageInternal;
globalThis.onMidiMessageExternal = ui.onMidiMessageExternal;
