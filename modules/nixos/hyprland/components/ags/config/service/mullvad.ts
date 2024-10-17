import { sh } from "lib/utils"

type Status = "disconnecting" | "disconnected" | "connecting" | "connected";

class Mullvad extends Service {
    #status: Status = "disconnected"

    get status() { 
        return this.#status
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
                    const statuses = ['Disconnecting', 'Disconnected', 'Connecting', 'Connected'];
                    const status = output.split(' ');
                    
                    if (status.length > 0 
                        && typeof status[0] === 'string' 
                        && statuses.includes(status[0])) {
                        this.#status = status[0].toLowerCase() as Status
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
        if (this.status === "connected") {
            await this.disconnect()
        } else {
            await this.connect()
        }
    }
}

export default new Mullvad
