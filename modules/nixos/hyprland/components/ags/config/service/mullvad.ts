import { sh } from "lib/utils"

type Status = "Disconnecting" | "Disconnected" | "Connecting" | "Connected";

class Mullvad extends Service {
    #status: Status = "Disconnected"

    get status() { 
        return this.#status
    }

    get statuses(): Status[] {
        return ["Disconnecting", "Disconnected", "Connecting", "Connected"]
    }

    get available() {
        return Utils.exec("which mullvad", () => true, () => false)
    }

    static {
        Service.register(this, {}, {
            "status": ["string", "r"],
        })
    }

    constructor() {
        super()

        if (this.available) {
            Utils.subprocess(
                // command to run, in an array just like execAsync
                ['mullvad', 'status', 'listen'],
            
                // callback when the program outputs something to stdout
                (output) => {
                    const status = output.split(' ');
                    
                    if (status.length > 0 
                        && typeof status[0] === 'string' 
                        && this.statuses.includes(status[0] as Status)) {
                        this.#status = status[0] as Status
                        this.changed("status")
                    }
                },
            )
        }
    }

    async connect() {
        await sh(`mullvad connect`)
    }

    async disconnect() {
        await sh(`mullvad disconnect`)
    }

    async reconnect() {
        await sh(`mullvad reconnect`)
    }

    async toggle() {
        if (this.status === "Connected") {
            await this.disconnect()
        } else {
            await this.connect()
        }
    }
}

export default new Mullvad
