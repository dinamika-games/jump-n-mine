# Third-party notices

Jump 'n' Mine is licensed under the MIT License; see [LICENSE](LICENSE).
This covers the code, the scenes, the shaders, the pictures (painted with an image generator from our prompts in `dev/pictures/prompts/`) and the synthesized fallback sounds.

The game includes, or is built with, the following third-party components.
Each keeps its own license.
The release packages carry all the license texts in the directory `licenses/`; the Windows package also the license text of CameraServerExtension.

## Distributed with the game

### Godot Engine

* Version: 4.6.2 (.NET)
* License: MIT
* Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur
* Source: https://godotengine.org
* License text: [licenses/godot/LICENSE.txt](licenses/godot/LICENSE.txt)

Godot Engine itself includes third-party components under their own licenses, e.g., FreeType, the fonts and the image libraries.
Their notices are in [licenses/godot/COPYRIGHT.txt](licenses/godot/COPYRIGHT.txt), generated from the Godot binary with `dev/write_godot_licenses.gd`.

### .NET runtime

* License: MIT
* Copyright (c) .NET Foundation and Contributors
* Source: https://github.com/dotnet/runtime
* Third-party notices: https://github.com/dotnet/runtime/blob/main/THIRD-PARTY-NOTICES.TXT

The .NET build of Godot bundles the .NET runtime with the exported game.

### ONNX Runtime

* Package: `Microsoft.ML.OnnxRuntime` 1.19.2
* License: MIT
* Copyright (c) Microsoft Corporation
* Source: https://github.com/microsoft/onnxruntime
* License text and third-party notices: included in the release packages as `licenses/onnxruntime/LICENSE` and `licenses/onnxruntime/ThirdPartyNotices.txt`

### CameraServerExtension (only in the Windows package)

* Version: 2026.03.27 (the prebuilt Windows x86_64 library of the release)
* License: MIT
* Copyright (c) 2024-present Jason Kuo
* Source: https://github.com/j20001970/godot-cameraserver-extension
* License text: [addons/CameraServerExtension/LICENSE](addons/CameraServerExtension/LICENSE)

Godot 4.6 implements no camera on Windows; the extension provides it there, with Media Foundation.

### YOLOX-Body-Head-Hand-Face (head detection)

* File: `scenes/vision/yolox/model/yolox_n_body_head_hand_face_post_1x3x256x320.onnx`
* License: Apache License 2.0
* Source: https://github.com/PINTO0309/PINTO_model_zoo/tree/main/434_YOLOX-Body-Head-Hand-Face, based on YOLOX by Megvii (https://github.com/Megvii-BaseDetection/YOLOX)
* License text: [scenes/vision/yolox/model/LICENSE](scenes/vision/yolox/model/LICENSE)

We distribute the model unmodified.

### YuNet (face landmarks)

* File: `scenes/vision/yunet/model/face_detection_yunet_2023mar_dynamic.onnx`
* License: MIT
* Source: https://github.com/opencv/opencv_zoo/tree/main/models/face_detection_yunet; its input made dynamic (any multiple of 32), otherwise unmodified
* License text: [scenes/vision/yunet/model/LICENSE](scenes/vision/yunet/model/LICENSE)

### SFace (face recognition)

* File: `scenes/vision/sface/model/face_recognition_sface_2021dec_int8.onnx`
* License: Apache License 2.0
* Source: https://github.com/opencv/opencv_zoo/tree/main/models/face_recognition_sface (by Yaoyao Zhong, converted by Chengrui Wang), unmodified
* License text: [scenes/vision/sface/model/LICENSE](scenes/vision/sface/model/LICENSE)

### RTMPose-t (body pose)

* File: `scenes/vision/rtmpose/model/rtmpose_t_body7_256x192.onnx`
* License: Apache License 2.0
* Source: https://github.com/open-mmlab/mmpose/tree/main/projects/rtmpose (MMPose by OpenMMLab), the ONNX export `rtmpose-t_simcc-body7_pt-body7_420e-256x192-026a1439_20230504` from https://download.openmmlab.com/mmpose/v1/projects/rtmposev1/onnx_sdk/, renamed, otherwise unmodified
* License text: [scenes/vision/rtmpose/model/LICENSE](scenes/vision/rtmpose/model/LICENSE)

### The sounds

* Files: `assets/sounds/*.ogg`, cut by `dev/sounds/cut_sounds.py` out of the recordings listed in `dev/sounds/sources.json`
* License: Creative Commons Zero (CC0 1.0), public domain; we checked the license on the page of every recording
* Source: [Freesound](https://freesound.org)

| Sound | Recording | Author |
|---|---|---|
| `hit_soft` | [Digging in wet course sand (1)](https://freesound.org/s/651292/) | f3bbbo |
| `hit_hard` | [Stone hit](https://freesound.org/s/431019/) | CamoMano |
| `break` | [Concrete SMASH 2](https://freesound.org/s/522099/) | magnuswaker |
| `swing` | [Whoosh](https://freesound.org/s/60013/) | qubodup |
| `gem` | [Item Sparkle](https://freesound.org/s/545238/) | Mr._Fritz_ |
| `booster` | [SFX Magic](https://freesound.org/s/264981/) | renatalmar |
| `fuse` | [sparkler_fuse_nm.wav](https://freesound.org/s/316682/) | Alex_hears_things |
| `explosion` | [explosion_03.wav](https://freesound.org/s/587183/) | derplayer |
| `splash` | [Splash](https://freesound.org/s/398032/) | swordofkings128 |
| `blub` | [bubble1.wav](https://freesound.org/s/235264/) | Godowan |
| `water_pour` | [small fountain](https://freesound.org/s/415027/) | roman_cgr |
| `sealed` | [thunk.wav](https://freesound.org/s/323725/) | Reitanna |
| `dragon` | [Dragon Roar](https://freesound.org/s/442964/) | qubodup |
| `spit` | [Fire Burst Flash](https://freesound.org/s/539972/) | Za-Games |
| `fizzle` | [cig_extinguish.wav](https://freesound.org/s/155660/) | the_semen_incident |
| `dizzy` | [Boing 2](https://freesound.org/s/540790/) | magnuswaker |
| `shielded` | [Bing1.wav](https://freesound.org/s/96132/) | BMacZero |
| `rope` | [ROPEMvmt_Rope Zip Fast_MP_1.wav](https://freesound.org/s/527394/) | MPierluissi |
| `select` | [Click.wav](https://freesound.org/s/256116/) | kwahmah_02 |
| `click` | [UI Button Click](https://freesound.org/s/467951/) | benzix2 |
| `won` | [Tada Fanfare A](https://freesound.org/s/397355/) | plasterbrain |
| `flooded` | [Fail Sound (Wa-Wa-Wah)](https://freesound.org/s/834512/) | YoshikaMiyafuji |

We thank the authors for giving their recordings to the public domain, even though CC0 does not ask for it.

## Used only for development, not distributed

| Component | Version | License | Source |
|---|---|---|---|
| xUnit.net (`xunit`, `xunit.runner.visualstudio`) | 2.9.3, 4.0.1 | Apache-2.0 | https://xunit.net |
| Microsoft.NET.Test.Sdk | 18.11.0 | MIT | https://github.com/microsoft/vstest |
| StbImageSharp | 2.30.16 | Unlicense or MIT | https://github.com/StbSharp/StbImageSharp |
| gdtoolkit (`gdformat`, `gdlint`) | 4.5.0 | MIT | https://github.com/Scony/godot-gdscript-toolkit |
| black | 24.10.0 | MIT | https://github.com/psf/black |

The test photos in `tests/JumpNMine.Tests/data/` are public-domain NASA photos: the scikit-image "astronaut" (Eileen Collins), and "Expedition 38 crew members pose for an in-flight crew portrait" (ISS038-E-054970).
