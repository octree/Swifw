import Foundation
import Socket

do {
    Vulcan.default.info("Local")
    let password = "ErcHtFO59ncoXd1R6axQywhMYtc4zRApVy+tQ7OjP8hZyQm1jiyCJkGpD4XGv2R9cIxslTBFe7w505foAqLlWHxnr02dNye7ADWllHaTDaZhA89Kp41zgfJADjJgRz6KaJLELh1r32/YwCEUF+q9mqGL60Y0JEuHIBkr+vTHG9q4ZXnm1LGQ+1J4Xt5f8ZnO1o8KHEieVIPt1S2wBK75uoYFn8paSX9pMYQGC8LDTm1qVRjz4pH/XNsevqucI/4BKtF08G5jxdmIshb9decR0vyb9bbj7HIM4KA20HqYqNwz91si4Yk9JR9WFTsTZjrBqu5+ljxEcRpP+ELkgO/MpA=="
    let bytePwd = try Password.loads(password: password)
    let local = SSLocal(password: bytePwd, listenAddr: Net.Address(host: "127.0.0.1", port: 1049), remoteAddr: Net.Address(host: "127.0.0.1", port: 1057))
    local.listen()
} catch {
    Vulcan.default.error("XX: \(error)")
}

print("Finished")
