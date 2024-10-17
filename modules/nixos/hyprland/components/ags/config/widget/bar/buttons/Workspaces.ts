import PanelButton from "../PanelButton"
import options from "options"
import { sh, range } from "lib/utils"

const hyprland = await Service.import("hyprland")
const { workspaces } = options.bar.workspaces

const dispatch = (arg: string | number) => {
    sh(`hyprctl dispatch workspace ${arg}`)
}

const Workspaces = (ws: number, monitor: number = 0) => Widget.Box({
    children: range(ws || 20).map(i => {
        const workspaceIndex = i + 10 * monitor;

        return Widget.Label({
            attribute: workspaceIndex,
            vpack: "center",
            label: `${workspaceIndex}`,
            setup: self => self.hook(hyprland, () => {
                self.toggleClassName("active", hyprland.active.workspace.id === workspaceIndex)
                self.toggleClassName("occupied", (hyprland.getWorkspace(workspaceIndex)?.windows || 0) > 0)
            }),
        });
    }),
    setup: box => {
        if (ws === 0) {
            box.hook(hyprland.active.workspace, () => box.children.map(btn => {
                btn.visible = hyprland.workspaces.some(ws => ws.id === btn.attribute)
            }))
        }
    },
})

export default (monitor: number) => PanelButton({
    window: "overview",
    class_name: "workspaces",
    on_scroll_up: () => dispatch("m-1"),
    on_scroll_down: () => dispatch("m+1"),
    on_clicked: () => App.toggleWindow("overview"),
    child: workspaces.bind().as((count) => Workspaces(count, monitor)),
})
