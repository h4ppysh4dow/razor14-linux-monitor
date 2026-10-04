function track(window) {
    let positioning = false;
    function place() {
        if (positioning || String(window.caption) !== "Razer 14 Monitor") return;
        const area = window.output.geometry;
        const size = window.frameGeometry;
        const x = area.x + area.width - size.width - 12;
        const y = area.y + 12;
        if (size.x === x && size.y === y) return;
        positioning = true;
        window.frameGeometry = {x: x, y: y, width: size.width, height: size.height};
        positioning = false;
    }
    window.captionChanged.connect(place);
    window.frameGeometryChanged.connect(place);
    window.outputChanged.connect(place);
    place();
}
workspace.windowAdded.connect(track);
for (const window of workspace.windowList()) track(window);
