//
//  EnergyReader.swift
//  Sapphire
//
//  Created by Shariq Charolia on 2025-11-08.
//

import Foundation
import AppKit

struct TopProcess: Identifiable, Equatable {
    var id: Int { pid }
    let pid: Int
    let name: String
    let usage: Double
}

class EnergyReader {
    private var timer: Timer?
    private let callback: ([TopProcess]) -> Void

    // `top -l 2` tarda algo más de un segundo en responder. Si el temporizador
    // fuese más rápido que eso acabaríamos con varios `top` vivos a la vez,
    // cada uno midiendo el consumo de los otros. El candado marca cuándo hay
    // una lectura en vuelo para no lanzar la siguiente encima.
    private let lock = NSLock()
    private var isReading = false

    init(callback: @escaping ([TopProcess]) -> Void) {
        self.callback = callback
    }

    func start() {
        read()
        // 15 s: el consumo por proceso cambia despacio y cada lectura cuesta un
        // proceso nuevo. A 5 s se notaba en la propia factura energética.
        let timer = Timer.scheduledCoalescing(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.read()
        }
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func read() {
        lock.lock()
        if isReading {
            lock.unlock()
            return
        }
        isReading = true
        lock.unlock()

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            defer {
                self.lock.lock()
                self.isReading = false
                self.lock.unlock()
            }

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/top")
            task.arguments = ["-o", "power", "-l", "2", "-n", "5", "-stats", "pid,command,power"]

            let pipe = Pipe()
            task.standardOutput = pipe

            do { try task.run() } catch { return }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            let output = String(data: data, encoding: .utf8) ?? ""

            let processes = self.parseTopOutput(output)

            DispatchQueue.main.async {
                // `NSRunningApplication` consulta el servidor de ventanas, así
                // que se resuelve aquí (en el hilo principal) y sólo para los
                // tres que se van a enseñar, no para los cinco que devuelve top.
                let named = processes.map { process -> TopProcess in
                    guard let app = NSRunningApplication(processIdentifier: pid_t(process.pid)),
                          let localized = app.localizedName else { return process }
                    return TopProcess(pid: process.pid, name: localized, usage: process.usage)
                }
                self.callback(named)
            }
        }
    }

    private func parseTopOutput(_ output: String) -> [TopProcess] {
        var processes: [TopProcess] = []
        let lines = output.split(separator: "\n")

        // `-l 2` pide dos muestras: en la primera el consumo es el acumulado
        // desde que arrancó el proceso, y sólo la segunda es el consumo real
        // del último intervalo. Por eso buscamos la ÚLTIMA cabecera, no la
        // primera: con la primera, un proceso viejo siempre ganaba la lista.
        guard let sampleStartIndex = lines.lastIndex(where: { $0.contains("PID") }) else { return [] }

        for line in lines.dropFirst(sampleStartIndex + 1) {
            let components = line.split(whereSeparator: \.isWhitespace)
            guard components.count >= 3,
                  let pid = Int(components[0]),
                  let power = Double(components[components.count - 1]) else { continue }

            let command = components.dropFirst().dropLast().joined(separator: " ")

            if power > 0 {
                processes.append(TopProcess(pid: pid, name: command, usage: power))
            }
        }

        return Array(processes.prefix(3))
    }
}
