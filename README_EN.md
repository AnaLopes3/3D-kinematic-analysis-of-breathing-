# Breathing Toolbox

A MATLAB toolbox for analyzing chest wall and abdominal movement during breathing, based on reflective marker data (motion capture). From the marker coordinates, it computes volumes, coordination variables and temporal variables for each respiratory cycle, and generates geometric animations of the movement.

## Workflow overview

1. Input format
2. Data preprocessing
3. Volume calculation
4. Respiratory cycle segmentation
5. Variable calculation
6. Geometric visualization

---

## Step 1 - Input format

Supported formats:

- `.c3d`
- `.txt` (with headlines), read by the `Import89.m` function
- `.xls`

**Required input information:** signal sampling frequency.

## Step 2 - Data preprocessing

- **Marker order check:** the input matrix must have the markers named in the correct sequence. One way to check this is a graphical verification before the analysis (see the model figures below).
- **NaN check and interpolation:** missing values are identified and the signal is interpolated when necessary.
- **Signal filtering:** the cutoff frequency can be chosen in three ways:
  - at the user's discretion;
  - with a predefined default value (simplifies use for non-expert users);
  - through spectral analysis, using the value suggested by the `Analise_espectral_filtro.m` function.

## Step 3 - Volume calculation

For the calculation to work, the markers must be named following the order shown in the images (checked in the previous step).

| Model | Method | Function | Note |
|---|---|---|---|
| 32 markers | Tetrahedra | `volume_32.m` | |
| 89 markers | Prism | `volume_89.m` | markers named from 0 to 88 |

> Add the model figures here (for example `docs/model_32.png`, `docs/model_89_front.png` and `docs/model_89_back.png`) and reference them with `![32-marker model](docs/model_32.png)`.

## Step 4 - Respiratory cycle segmentation

Respiratory cycles are cut from minimum to minimum by the `corte.m` function, which has two outputs:

- **normalized** respiratory cycle;
- **non-normalized** respiratory cycle.

Whether a cycle is normalized or not matters in the next step.

## Step 5 - Variable calculation

### Volume (`var_derived_volume.m`)

Can be calculated from either the normalized or the non-normalized cycle.

- Inspiratory tidal volume
- Inspiratory percentage contribution
- Rib cage percentage contribution

### Coordination (`var_derived_phaseangle.m`)

Calculated using the **mean cycle**. This brings the curve closer to a sinusoidal pattern and reduces the chance of noise in the signal, which could be mistaken for an apparent inspiration-expiration phase shift.

- Phase angle

### Temporal (`var_derived_time.m`)

Calculated from the **non-normalized** cycle.

- Total cycle time
- Inspiratory time
- Inspiratory time / total time
- Lag between respiratory peaks (Tlag), in frames
- Tlag relative to total cycle time and in degrees

## Step 6 - Geometric visualization

- Animation of the 32-marker movement in `.mp4`: `create_animation.m`
- Animation of the 89-marker movement in `.mp4`: **to do**

---

## Function summary

| Function | Step | Description |
|---|---|---|
| `Import89.m` | Input | Imports `.txt` files with headlines |
| `Analise_espectral_filtro.m` | Preprocessing | Spectral analysis to choose the filter frequency |
| `volume_32.m` | Volume | Volume by the tetrahedra method (32 markers) |
| `volume_89.m` | Volume | Volume by the prism method (89 markers) |
| `corte.m` | Cycles | Cycle segmentation from minimum to minimum (normalized and non-normalized) |
| `var_derived_volume.m` | Variables | Tidal volume and percentage contributions |
| `var_derived_phaseangle.m` | Variables | Phase angle (coordination) |
| `var_derived_time.m` | Variables | Temporal variables and Tlag |
| `create_animation.m` | Visualization | `.mp4` animation of the 32-marker model |

## To do

- [ ] `.mp4` animation for the 89-marker model
- [ ] Add usage examples and test data
- [ ] Choose a project license

## How to cite

Article in preparation: *Breathing Toolbox*. Update this section with the full reference once it is published.
