import Foundation

struct OptionValue: Hashable {
    let displayName: String
    let parameterValue: String
}


struct AdditionalOption: Hashable {
    let parameterName: String
    let uiName: String
    let values: [OptionValue]
}

struct SeparationModel: Identifiable, Hashable {
    let id: Int
    let name: String
    let additionalOptions: [AdditionalOption]?
}

struct OutputFormat: Identifiable, Hashable {
    let id: Int
    let name: String
}


struct SeparatedFile: Identifiable, Hashable {
    let id = UUID()
    let fileName: String
    let downloadURL: String
}

struct AppData {
    static let models: [SeparationModel] = [
        SeparationModel(
            id: 0, name: "spleeter",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "2 stems (vocals, music)", parameterValue: "0"),
                    OptionValue(displayName: "4 stems (vocals, drums, bass, other)", parameterValue: "1"),
                    OptionValue(displayName: "5 stems (vocals, drums, bass, piano, other)", parameterValue: "2")
                ])
            ]),
        SeparationModel(
            id: 3, name: "UnMix",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "unmix XL", parameterValue: "0"),
                    OptionValue(displayName: "unmix HQ", parameterValue: "1"),
                    OptionValue(displayName: "unmix SD", parameterValue: "2"),
                    OptionValue(displayName: "unmix SE (low quality)", parameterValue: "3")
                ])
            ]),
        SeparationModel(
            id: 7, name: "MDX A/B (vocals, drums, bass, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Vocal Model Type", values: [
                    OptionValue(displayName: "MDX A (Contest Version)", parameterValue: "0"),
                    OptionValue(displayName: "MDX Kimberley Jensen (New)", parameterValue: "3"),
                    OptionValue(displayName: "MDX UVR 2022.01.01", parameterValue: "1"),
                    OptionValue(displayName: "MDX UVR 2022.07.25", parameterValue: "2")
                ])
            ]),
        SeparationModel(
            id: 9, name: "Ultimate Vocal Remover VR (vocals, music)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "HP2-4BAND-3090_4band_arch-500m_1", parameterValue: "0"),
                    OptionValue(displayName: "HP2-4BAND-3090_4band_2", parameterValue: "1"),
                    OptionValue(displayName: "HP-4BAND-V2", parameterValue: "7"),
                    OptionValue(displayName: "HP-KAROKEE-MSB2-3BAND-3090", parameterValue: "8"),
                    OptionValue(displayName: "UVR-De-Echo-Aggressive", parameterValue: "13"),
                    OptionValue(displayName: "UVR-De-Echo-Normal", parameterValue: "14"),
                    OptionValue(displayName: "UVR-DeNoise", parameterValue: "15"),
                    OptionValue(displayName: "UVR-DeEcho-DeReverb", parameterValue: "16")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "Aggressiveness", values: [
                    OptionValue(displayName: "0.1", parameterValue: "0.1"), OptionValue(displayName: "0.2", parameterValue: "0.2"),
                    OptionValue(displayName: "0.3", parameterValue: "0.3"), OptionValue(displayName: "0.4", parameterValue: "0.4"),
                    OptionValue(displayName: "0.5", parameterValue: "0.5"), OptionValue(displayName: "0.6", parameterValue: "0.6"),
                    OptionValue(displayName: "0.7", parameterValue: "0.7"), OptionValue(displayName: "0.8", parameterValue: "0.8"),
                    OptionValue(displayName: "0.9", parameterValue: "0.9"), OptionValue(displayName: "1.0", parameterValue: "1.0")
                ])
            ]),
        SeparationModel(
            id: 10, name: "Demucs3 Model (vocals, drums, bass, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Demucs3 Model A (Contest)", parameterValue: "0"),
                    OptionValue(displayName: "Demucs3 Model B (High Quality)", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 12, name: "MDX-B Karaoke (lead/back vocals)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Karaoke Model Type", values: [
                    OptionValue(displayName: "Extract directly from mixture", parameterValue: "0"),
                    OptionValue(displayName: "Extract from vocals part", parameterValue: "1")
                ])
            ]),
        SeparationModel(id: 13, name: "Demucs2 (vocals, drums, bass, other)", additionalOptions: nil),
        SeparationModel(
            id: 14, name: "Zero Shot (Query Based) (Low quality)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Bass", parameterValue: "0"),
                    OptionValue(displayName: "Drums", parameterValue: "1"),
                    OptionValue(displayName: "Vocals", parameterValue: "2"),
                    OptionValue(displayName: "Other", parameterValue: "3")
                ])
            ]),
        SeparationModel(id: 15, name: "Danna Sep (vocals, drums, bass, other)", additionalOptions: nil),
        SeparationModel(id: 16, name: "Byte Dance (vocals, drums, bass, other)", additionalOptions: nil),
        SeparationModel(
            id: 17, name: "UVRv5 Demucs (vocals, music)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "UVR_Demucs_Model_1", parameterValue: "0"),
                    OptionValue(displayName: "UVR_Demucs_Model_2", parameterValue: "1"),
                    OptionValue(displayName: "UVR_Demucs_Model_Bag", parameterValue: "2")
                ])
            ]),
        SeparationModel(id: 18, name: "MVSep DNR (music, sfx, speech)", additionalOptions: nil),
        SeparationModel(id: 19, name: "MVSep Vocal Model (vocals, music)", additionalOptions: nil),
        SeparationModel(
            id: 20, name: "Demucs4 HT (vocals, drums, bass, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Quality", values: [
                    OptionValue(displayName: "High Quality, Slow", parameterValue: "0"),
                    OptionValue(displayName: "Good Quality, Fast", parameterValue: "1"),
                    OptionValue(displayName: "6 Stems (inc. piano/guitar)", parameterValue: "2")
                ])
            ]),
        SeparationModel(
            id: 22, name: "Reverb Removal (noreverb)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "by FoxJoy", parameterValue: "0"),
                    OptionValue(displayName: "by anvuew (MelRoformer)", parameterValue: "1"),
                    OptionValue(displayName: "by anvuew (BSRoformer)", parameterValue: "2"),
                    OptionValue(displayName: "by anvuew v2 (MelRoformer)", parameterValue: "3"),
                    OptionValue(displayName: "by Sucial (MelRoformer)", parameterValue: "4"),
                    OptionValue(displayName: "by Sucial v2 (MelRoformer)", parameterValue: "5")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "Preprocess", values: [
                    OptionValue(displayName: "Extract vocals (needed for Mel/BS Roformer)", parameterValue: "0"),
                    OptionValue(displayName: "Use as is", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 23, name: "MDX B (vocals, instrumental)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Vocal Model Type", values: [
                    OptionValue(displayName: "Kimberley Jensen v2", parameterValue: "7"),
                    OptionValue(displayName: "MDX UVR 2022.01.01", parameterValue: "0"),
                    OptionValue(displayName: "Kimberley Jensen v1", parameterValue: "2"),
                    OptionValue(displayName: "UVR-MDX-NET-Inst_HQ_2", parameterValue: "4"),
                    OptionValue(displayName: "UVR-MDX-NET-Inst_HQ_3", parameterValue: "8"),
                    OptionValue(displayName: "UVR-MDX-NET-Inst_HQ_4", parameterValue: "11"),
                    OptionValue(displayName: "UVR-MDX-NET-Inst_HQ_5", parameterValue: "12")
                ])
            ]),
        SeparationModel(
            id: 24, name: "MVSep Demucs4HT DNR (dialog, sfx, music)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Single", parameterValue: "0"),
                    OptionValue(displayName: "Ensemble", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 25, name: "MDX23C (vocals, instrumental)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Vocal Model Type", values: [
                    OptionValue(displayName: "12K FFT, Large Conv, Hop 1024", parameterValue: "3"),
                    OptionValue(displayName: "12K FFT, Large Conv", parameterValue: "2"),
                    OptionValue(displayName: "12K FFT", parameterValue: "0"),
                    OptionValue(displayName: "12K FFT, 6 Poolings", parameterValue: "1"),
                    OptionValue(displayName: "8K FFT (SDR 10.17)", parameterValue: "4"),
                    OptionValue(displayName: "8K FFT (SDR 10.36)", parameterValue: "7")
                ])
            ]),
        SeparationModel(
            id: 26, name: "Ensemble (vocals, instrum)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Output Files", values: [
                    OptionValue(displayName: "Standard set", parameterValue: "0"),
                    OptionValue(displayName: "Include intermediate results", parameterValue: "1")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "Model Version", values: [
                    OptionValue(displayName: "SDR 10.44", parameterValue: "1"), OptionValue(displayName: "SDR 10.75", parameterValue: "2"),
                    OptionValue(displayName: "SDR 11.06", parameterValue: "3"), OptionValue(displayName: "SDR 11.33", parameterValue: "4"),
                    OptionValue(displayName: "SDR 11.50", parameterValue: "5"), OptionValue(displayName: "SDR 11.61", parameterValue: "6")
                ])
            ]),
        SeparationModel(id: 27, name: "Demucs4 Vocals 2023 (vocals, instrum)", additionalOptions: nil),
        SeparationModel(
            id: 28, name: "Ensemble (vocals, instrum, bass, drums, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Output Files", values: [
                    OptionValue(displayName: "Standard set", parameterValue: "0"),
                    OptionValue(displayName: "Include intermediate results", parameterValue: "1")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "Model Version", values: [
                    OptionValue(displayName: "SDR 11.21", parameterValue: "1"), OptionValue(displayName: "SDR 11.87", parameterValue: "2"),
                    OptionValue(displayName: "SDR 12.03", parameterValue: "3"), OptionValue(displayName: "SDR 12.17", parameterValue: "4"),
                    OptionValue(displayName: "SDR 12.34", parameterValue: "5"), OptionValue(displayName: "SDR 12.66", parameterValue: "6"),
                    OptionValue(displayName: "SDR 12.76", parameterValue: "7"), OptionValue(displayName: "SDR 12.84", parameterValue: "8"),
                    OptionValue(displayName: "SDR 13.01", parameterValue: "9"), OptionValue(displayName: "SDR 13.07", parameterValue: "10")
                ])
            ]),
        SeparationModel(
            id: 29, name: "MVSep Piano (piano, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Piano Model Type", values: [
                    OptionValue(displayName: "mdx23c (2023.08)", parameterValue: "0"), OptionValue(displayName: "mdx23c (2024.09)", parameterValue: "1"),
                    OptionValue(displayName: "MelRoformer", parameterValue: "2"), OptionValue(displayName: "SCNet Large", parameterValue: "3"),
                    OptionValue(displayName: "Ensemble (SCNet + Mel)", parameterValue: "4"), OptionValue(displayName: "BS Roformer SW", parameterValue: "5")
                ])
            ]),
        SeparationModel(
            id: 30, name: "Ensemble All-In (vocals, bass, drums, piano, etc.)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Output Files", values: [
                    OptionValue(displayName: "Standard set", parameterValue: "0"),
                    OptionValue(displayName: "Include intermediate results", parameterValue: "1")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "Model Version", values: [
                    OptionValue(displayName: "SDR 11.21", parameterValue: "1"), OptionValue(displayName: "SDR 11.87", parameterValue: "2"),
                    OptionValue(displayName: "SDR 12.03", parameterValue: "3"), OptionValue(displayName: "SDR 12.17", parameterValue: "4"),
                    OptionValue(displayName: "SDR 12.32", parameterValue: "5"), OptionValue(displayName: "SDR 12.66", parameterValue: "6"),
                    OptionValue(displayName: "SDR 12.76", parameterValue: "7"), OptionValue(displayName: "SDR 12.84", parameterValue: "8"),
                    OptionValue(displayName: "SDR 13.01", parameterValue: "9"), OptionValue(displayName: "SDR 13.07", parameterValue: "10")
                ])
            ]),
        SeparationModel(
            id: 31, name: "MVSep Guitar (guitar, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Guitar Model Type", values: [
                    OptionValue(displayName: "mdx23c (2023.08)", parameterValue: "0"), OptionValue(displayName: "mdx23c (2024.06)", parameterValue: "2"),
                    OptionValue(displayName: "MelRoformer", parameterValue: "3"), OptionValue(displayName: "BSRoformer", parameterValue: "5"),
                    OptionValue(displayName: "Ensemble (BS + Mel)", parameterValue: "6"), OptionValue(displayName: "BS Roformer SW", parameterValue: "7")
                ])
            ]),
        SeparationModel(
            id: 33, name: "Vit Large 23 (vocals, instrum)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "v1", parameterValue: "0"),
                    OptionValue(displayName: "v2", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 34, name: "MVSep Crowd removal (crowd, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "MDX23C v1", parameterValue: "8"),
                    OptionValue(displayName: "MDX23C v2", parameterValue: "9"),
                    OptionValue(displayName: "Mel Roformer", parameterValue: "0"),
                    OptionValue(displayName: "Ensemble MDX23C + Mel Roformer", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 35, name: "MVSep MelBand Roformer (vocals, instrum)", additionalOptions: nil
        ),
        SeparationModel(
            id: 36, name: "Bandit Plus (speech, music, effects)", additionalOptions: nil // Bandit Plus is not in docs, Bandit v2 is
        ),
        SeparationModel(
            id: 37, name: "DrumSep (4-6 stems: kick, snare, cymbals, etc.)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "by inagoy (HDemucs, 4 stems)", parameterValue: "0"),
                    OptionValue(displayName: "by aufr33/jarredou (MDX23C, 4 stems)", parameterValue: "1"),
                    OptionValue(displayName: "SCNet XL (5 stems)", parameterValue: "2"),
                    OptionValue(displayName: "SCNet XL (6 stems)", parameterValue: "3"),
                    OptionValue(displayName: "Ensemble of 4 models (8 stems)", parameterValue: "5"),
                    OptionValue(displayName: "MelBand Roformer (4 stems)", parameterValue: "6"),
                    OptionValue(displayName: "MelBand Roformer (6 stems)", parameterValue: "7")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "Preprocess", values: [
                    OptionValue(displayName: "Apply Drums model before", parameterValue: "0"),
                    OptionValue(displayName: "Use as is (audio must contain drums only)", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 38, name: "LarsNet (kick, snare, cymbals, toms, hihat)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Apply Demucs4HT first", parameterValue: "0"),
                    OptionValue(displayName: "Use as is (audio must contain drums only)", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 39, name: "Whisper (extract text from audio)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Apply to original file", parameterValue: "0"),
                    OptionValue(displayName: "Extract vocals first", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 40, name: "BS Roformer (vocals, instrumental)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Vocal Model Type", values: [
                    OptionValue(displayName: "ver. 2024.02", parameterValue: "3"),
                    OptionValue(displayName: "viperx edition", parameterValue: "4"),
                    OptionValue(displayName: "ver 2024.04", parameterValue: "5"),
                    OptionValue(displayName: "ver 2024.08", parameterValue: "29")
                ])
            ]),
        SeparationModel(
            id: 41, name: "MVSep Bass (bass, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Bass Model Type", values: [
                    OptionValue(displayName: "BS Roformer", parameterValue: "0"),
                    OptionValue(displayName: "HTDemucs4", parameterValue: "1"),
                    OptionValue(displayName: "SCNet XL", parameterValue: "2"),
                    OptionValue(displayName: "BS + HTDemucs + SCNet", parameterValue: "3"),
                    OptionValue(displayName: "BS Roformer SW", parameterValue: "4"),
                    OptionValue(displayName: "BS Roformer SW + SCNet XL", parameterValue: "5")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "How To Extract", values: [
                    OptionValue(displayName: "Extract directly from mixture", parameterValue: "0"),
                    OptionValue(displayName: "Extract from instrumental part", parameterValue: "1")
                ]),
                AdditionalOption(parameterName: "add_opt3", uiName: "Output Files", values: [
                    OptionValue(displayName: "Standard set", parameterValue: "0"),
                    OptionValue(displayName: "Include results of independent models", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 42, name: "MVSep MultiSpeaker (MDX23C)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Extract directly from mixture", parameterValue: "0"),
                    OptionValue(displayName: "Extract from vocals part", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 43, name: "MVSep Multichannel BS (vocals, instrumental)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "BS Roformer", parameterValue: "0"),
                    OptionValue(displayName: "MDX23C", parameterValue: "1"),
                    OptionValue(displayName: "MelBand Roformer", parameterValue: "2"),
                    OptionValue(displayName: "MelBand Roformer XL", parameterValue: "3")
                ])
            ]),
        SeparationModel(
            id: 44, name: "MVSep Drums (drums, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Drums Model Type", values: [
                    OptionValue(displayName: "HTDemucs", parameterValue: "0"),
                    OptionValue(displayName: "MelBand Roformer", parameterValue: "1"),
                    OptionValue(displayName: "SCNet Large", parameterValue: "2"),
                    OptionValue(displayName: "SCNet XL", parameterValue: "3"),
                    OptionValue(displayName: "Mel + SCNet XL", parameterValue: "4"),
                    OptionValue(displayName: "BS Roformer SW", parameterValue: "5"),
                    OptionValue(displayName: "Mel + SCNet XL + BS Roformer SW", parameterValue: "6")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "How To Extract", values: [
                    OptionValue(displayName: "Extract directly from mixture", parameterValue: "0"),
                    OptionValue(displayName: "Extract from instrumental part", parameterValue: "1")
                ]),
                AdditionalOption(parameterName: "add_opt3", uiName: "Output Files", values: [
                    OptionValue(displayName: "Standard set", parameterValue: "0"),
                    OptionValue(displayName: "Include results of independent models", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 45, name: "Bandit v2 (speech, music, effects)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Multi language model", parameterValue: "0"),
                    OptionValue(displayName: "English model", parameterValue: "1"),
                    OptionValue(displayName: "German model", parameterValue: "2"),
                    OptionValue(displayName: "French model", parameterValue: "3"),
                    OptionValue(displayName: "Spanish model", parameterValue: "4"),
                    OptionValue(displayName: "Chinese model", parameterValue: "5"),
                    OptionValue(displayName: "Faroese model", parameterValue: "6")
                ])
            ]),
        SeparationModel(
            id: 46, name: "SCNet (vocals, instrumental)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Vocal Model Type", values: [
                    OptionValue(displayName: "SCNet", parameterValue: "0"),
                    OptionValue(displayName: "SCNet Large", parameterValue: "1"),
                    OptionValue(displayName: "SCNet XL", parameterValue: "2"),
                    OptionValue(displayName: "SCNet XL (high fullness)", parameterValue: "3"),
                    OptionValue(displayName: "SCNet XL (very high fullness)", parameterValue: "4"),
                    OptionValue(displayName: "SCNet XL IHF", parameterValue: "5")
                ])
            ]),
        SeparationModel(
            id: 47, name: "DeNoise by aufr33",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Standard", parameterValue: "0"),
                    OptionValue(displayName: "Aggressive", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 48, name: "MelBand Roformer (vocals, instrumental)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Vocal Model Type", values: [
                    OptionValue(displayName: "Kimberley Jensen edition", parameterValue: "0"),
                    OptionValue(displayName: "ver 2024.08", parameterValue: "1"),
                    OptionValue(displayName: "Bas Curtiz edition", parameterValue: "2"),
                    OptionValue(displayName: "unwa Instrumental v1", parameterValue: "3"),
                    OptionValue(displayName: "unwa Instrumental v1e", parameterValue: "5"),
                    OptionValue(displayName: "unwa big beta v5e", parameterValue: "6"),
                    OptionValue(displayName: "ver 2024.10", parameterValue: "4"),
                    OptionValue(displayName: "becruily instrum high fullness", parameterValue: "7"),
                    OptionValue(displayName: "becruily vocals high fullness", parameterValue: "8"),
                    OptionValue(displayName: "unwa Instrumental v1e plus", parameterValue: "9")
                ])
            ]),
        SeparationModel(
            id: 49, name: "MelBand Karaoke (lead/back vocals)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Karaoke Model Type", values: [
                    OptionValue(displayName: "Model by viperx and aufr33", parameterValue: "0"),
                    OptionValue(displayName: "Model by becruily", parameterValue: "1")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "Extraction Type", values: [
                    OptionValue(displayName: "Use as is", parameterValue: "0"),
                    OptionValue(displayName: "Extract vocals first", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 50, name: "Aspiration (by Sucial)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Extract directly from mixture", parameterValue: "0"),
                    OptionValue(displayName: "Extract from vocals part", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 51, name: "Apollo Enhancers (by JusperLee and Lew)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "MP3 Enhancer", parameterValue: "0"),
                    OptionValue(displayName: "Universal Super Resolution (by Lew)", parameterValue: "1"),
                    OptionValue(displayName: "Vocals Super Resolution (by Lew)", parameterValue: "2"),
                    OptionValue(displayName: "Universal Super Resolution (by MVSep Team)", parameterValue: "3")
                ])
            ]),
        SeparationModel(id: 52, name: "MVSep Strings (strings, other)", additionalOptions: nil),
        SeparationModel(
            id: 53, name: "Medley Vox (Multi-singer separation)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "Apply to original file", parameterValue: "0"),
                    OptionValue(displayName: "Extract vocals first", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 54, name: "MVSep Wind (wind, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Wind Model Type", values: [
                    OptionValue(displayName: "MelBand Roformer", parameterValue: "0"),
                    OptionValue(displayName: "SCNet Large", parameterValue: "1"),
                    OptionValue(displayName: "Mel + SCNet", parameterValue: "2")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "How to Extract", values: [
                    OptionValue(displayName: "Extract directly from mixture", parameterValue: "0"),
                    OptionValue(displayName: "Extract from instrumental part", parameterValue: "1")
                ]),
                AdditionalOption(parameterName: "add_opt3", uiName: "Output Files", values: [
                    OptionValue(displayName: "Standard set", parameterValue: "0"),
                    OptionValue(displayName: "Include results of independent models", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 55, name: "Phantom Centre extraction (by wesleyr36)", additionalOptions: nil
        ),
        SeparationModel(
            id: 56, name: "MVSep DnR v3 (speech, music, sfx)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "SCNet Large", parameterValue: "0"),
                    OptionValue(displayName: "MelBand Roformer", parameterValue: "1"),
                    OptionValue(displayName: "Mel + SCNet", parameterValue: "2")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "How To Extract", values: [
                    OptionValue(displayName: "Extract directly from mixture", parameterValue: "0"),
                    OptionValue(displayName: "Use vocals model to help", parameterValue: "1")
                ]),
                AdditionalOption(parameterName: "add_opt3", uiName: "Output Files", values: [
                    OptionValue(displayName: "Standard set", parameterValue: "0"),
                    OptionValue(displayName: "Include results of independent models", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 57, name: "MVSep Male/Female separation",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "BSRoformer by Sucial", parameterValue: "0"),
                    OptionValue(displayName: "BSRoformer by aufr33", parameterValue: "3"),
                    OptionValue(displayName: "SCNet XL", parameterValue: "1"),
                    OptionValue(displayName: "MelRoformer (2025.01)", parameterValue: "2")
                ]),
                AdditionalOption(parameterName: "add_opt2", uiName: "How To Extract", values: [
                    OptionValue(displayName: "Extract directly from mixture", parameterValue: "0"),
                    OptionValue(displayName: "Extract vocals first with BS Roformer", parameterValue: "1")
                ])
            ]),
        SeparationModel(
            id: 58, name: "MVSep Organ (organ, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Organ Model Type", values: [
                    OptionValue(displayName: "SCNet XL", parameterValue: "0"),
                    OptionValue(displayName: "MelBand Roformer", parameterValue: "1"),
                    OptionValue(displayName: "Mel + SCNet", parameterValue: "2")
                ])
            ]),
        SeparationModel(
            id: 59, name: "AudioSR (Super Resolution)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Cutoff (Hz)", values: [
                    OptionValue(displayName: "Automatic", parameterValue: "0"),
                    OptionValue(displayName: "2000 Hz", parameterValue: "2000"), OptionValue(displayName: "3000 Hz", parameterValue: "3000"),
                    OptionValue(displayName: "4000 Hz", parameterValue: "4000"), OptionValue(displayName: "5000 Hz", parameterValue: "5000"),
                    OptionValue(displayName: "6000 Hz", parameterValue: "6000"), OptionValue(displayName: "7000 Hz", parameterValue: "7000"),
                    OptionValue(displayName: "8000 Hz", parameterValue: "8000"), OptionValue(displayName: "9000 Hz", parameterValue: "9000"),
                    OptionValue(displayName: "10000 Hz", parameterValue: "10000"), OptionValue(displayName: "11000 Hz", parameterValue: "11000"),
                    OptionValue(displayName: "12000 Hz", parameterValue: "12000"), OptionValue(displayName: "13000 Hz", parameterValue: "13000"),
                    OptionValue(displayName: "14000 Hz", parameterValue: "14000"), OptionValue(displayName: "15000 Hz", parameterValue: "15000"),
                    OptionValue(displayName: "16000 Hz", parameterValue: "16000"), OptionValue(displayName: "17000 Hz", parameterValue: "17000"),
                    OptionValue(displayName: "18000 Hz", parameterValue: "18000"), OptionValue(displayName: "19000 Hz", parameterValue: "19000"),
                    OptionValue(displayName: "20000 Hz", parameterValue: "20000"), OptionValue(displayName: "21000 Hz", parameterValue: "21000"),
                    OptionValue(displayName: "22000 Hz", parameterValue: "22000")
                ])
            ]),
        SeparationModel(id: 60, name: "FlashSR (Super Resolution)", additionalOptions: nil),
        SeparationModel(
            id: 61, name: "MVSep Saxophone (saxophone, other)",
            additionalOptions: [
                AdditionalOption(parameterName: "add_opt1", uiName: "Model Type", values: [
                    OptionValue(displayName: "SCNet XL", parameterValue: "0"),
                    OptionValue(displayName: "MelBand Roformer", parameterValue: "1"),
                    OptionValue(displayName: "Mel + SCNet", parameterValue: "2")
                ])
            ]),
        SeparationModel(id: 62, name: "Stable Audio Open Gen", additionalOptions: nil), 
        SeparationModel(id: 63, name: "BS Roformer SW (vocals, bass, drums, guitar, piano, other)", additionalOptions: nil)
    ]
    
    static let outputFormats: [OutputFormat] = [
        OutputFormat(id: 0, name: "mp3 (320 kbps)"),
        OutputFormat(id: 1, name: "wav (uncompressed)"),
        OutputFormat(id: 2, name: "flac (lossless)"),
        OutputFormat(id: 3, name: "m4a (lossy)")
    ]
}

struct SubmitResponse: Codable {
    let success: Bool
    struct SubmitData: Codable {
        let hash: String
    }
    let data: SubmitData?
}

struct ErrorResponse: Codable {
    let success: Bool
    let errors: [String]
}

struct APIFileResult: Codable, Hashable {
    let type: String
    let url: String
    let download: String
}

struct StatusResponse: Codable {
    let success: Bool
    let status: String
    
    struct StatusData: Codable {
        // --- FIX 4 ---
        let files: [APIFileResult]?
        
        let message: String?
    }
    
    let data: StatusData?
}
