//
//  SocketServer.swift
//  WebScoketPractice
//
//  Created by 劉丞恩 on 2024/3/23.
//

import Foundation
import Network

class Client: NSObject, Identifiable { //this is a class that sever connect with client after sever receive client's request
    let id = UUID()
    private var server: SocketServer!
    private var conn: NWConnection?
    
    init(_ server: SocketServer,  _ connection: NWConnection) {
        super.init()
        self.server = server
        conn = connection
        conn?.stateUpdateHandler = stateChanged(_:)
        conn?.start(queue: .global())  //ready to connect with client
    }
    
    private func stateChanged(_ state: NWConnection.State) { //check if client sending the data
        switch state {
        case .ready:
            receive()
            print("connection ready")
            
        case .failed(let error):
            disconnect()
            print("connection faile: \(error)")
            
        case .cancelled:
            disconnect()
            print("connection cancel")
            
        default:
            print("connection state: \(state)")
        }
    }
    
    func send(_data: Data){
        //send data
        conn?.send(content: _data, completion: .contentProcessed({ error in
            guard error == nil else {
                print("ERROR: {\(#function)} \(error!.localizedDescription)")
                self.conn?.cancel()
                return
            }
        }))
    }
    
    func receive() {
        //receive data
        conn?.receive(minimumIncompleteLength: 1, maximumLength: Int.max, completion: { data, context, isComplete, error in
            guard error == nil else {
                print("ERROR: {\(#function)} \(error!.localizedDescription)")
                self.conn?.cancel()
                return
            }
            
            guard let data = data else {
                print("ERROR: {\(#function)} receive nil")
                self.conn?.cancel()
                return
            }
            
            // 範例：收到資料後原封不動送回去
            self.send(_data: data)
            // 除錯訊息
            if let string = String(data: data, encoding: .utf8) {
                print("received: \(string)")
            }
            // 繼續等下一筆資料
            self.receive()
        })
    }
    
    func disconnect() {
        conn = nil
        if let index = server.clients.firstIndex(where: { client in
            client.id == self.id
        }) {
            server.clients.remove(at: index)
        }
    }
}

class SocketServer: NSObject {
    var clients: [Client] = []
    
    init?(port: NWEndpoint.Port) { //init a listener
        super.init()
        do {
            let listener = try NWListener(using: .tcp, on: port)
            listener.stateUpdateHandler = stateChanged(_:)
            listener.newConnectionHandler = accept(connection:)
            //when recieve client's request, it will call connection func(func is what you want to call)
            listener.start(queue: .global())
        } catch {
            print(error)
            return nil
        }
    }
    
    private func stateChanged(_ state: NWListener.State) { //give stateChange a func
        switch state {
        case .ready:
            print("listener ready")
            
        case .failed(let error):
            print("listener faile: \(error)")
            
        default:
            print("listener state: \(state)")
        }
    }
    
    private func accept(connection: NWConnection) {
        //if there have a client request. here will create a Client()
        clients.append(Client(self, connection))
    }
}
