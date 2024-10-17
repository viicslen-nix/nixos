import { SimpleToggleButton } from "../ToggleButton"
import icons from "lib/icons"
import mullvad from "service/mullvad"

export const Mullvad = () => SimpleToggleButton({
    icon: mullvad.bind('status').as(status => icons.mullvad[status]),
    label: mullvad.bind('status'),
    connection: [mullvad, () => mullvad.status === "Connected"],
    toggle: () => mullvad.toggle(),
})
