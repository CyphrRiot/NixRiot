.pragma library

//
//

//
//
//
var list = [
    { id: "nothing",  name: "NixRiot",     bg: "#000000", fg: "#ffffff", on: "#ffffff", ok: "#ffffff", crit: "#d71921" }
];

function of(id) {
    for (var i = 0; i < list.length; i++)
        if (list[i].id === id) return list[i];
    return list[0];
}
