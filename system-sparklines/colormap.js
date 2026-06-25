// colormap.js — matplotlib perceptual colormaps as sampled stops + a lerp.
// Pure, dual-target (QML import + node require). No .pragma library.

var MAPS = {
    viridis: [[0.267,0.005,0.329],[0.283,0.141,0.458],[0.254,0.265,0.530],[0.207,0.372,0.553],[0.164,0.471,0.558],[0.128,0.567,0.551],[0.478,0.821,0.318],[0.993,0.906,0.144]],
    plasma:  [[0.050,0.030,0.528],[0.298,0.008,0.631],[0.494,0.012,0.658],[0.659,0.134,0.588],[0.798,0.280,0.469],[0.901,0.420,0.364],[0.973,0.620,0.197],[0.940,0.975,0.131]],
    inferno: [[0.001,0.000,0.014],[0.124,0.047,0.282],[0.333,0.059,0.429],[0.533,0.133,0.416],[0.729,0.212,0.333],[0.890,0.350,0.200],[0.979,0.650,0.040],[0.988,1.000,0.645]],
    magma:   [[0.001,0.000,0.014],[0.110,0.063,0.267],[0.310,0.071,0.482],[0.506,0.145,0.506],[0.710,0.212,0.478],[0.898,0.314,0.392],[0.984,0.529,0.380],[0.988,0.992,0.749]],
    cividis: [[0.000,0.135,0.305],[0.000,0.205,0.387],[0.255,0.286,0.404],[0.365,0.366,0.412],[0.471,0.447,0.421],[0.584,0.531,0.402],[0.730,0.622,0.346],[0.996,0.910,0.216]]
};

var COLORMAP_NAMES = ["viridis", "plasma", "inferno", "magma", "cividis"];

function sample(name, t) {
    var stops = MAPS[name] || MAPS.viridis;
    var x = t < 0 ? 0 : (t > 1 ? 1 : t);
    var f = x * (stops.length - 1);
    var i = Math.floor(f);
    var k = f - i;
    if (i >= stops.length - 1)
        return stops[stops.length - 1].slice();
    var a = stops[i], b = stops[i + 1];
    return [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k];
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { MAPS: MAPS, COLORMAP_NAMES: COLORMAP_NAMES, sample: sample };
}
