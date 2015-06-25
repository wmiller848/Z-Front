extern crate mio;

use mio::*;
use mio::tcp::{TcpListener, TcpStream};
use std::io::{Read, Write};

// Setup some tokens to allow us to identify which event is
// for which socket.
const SERVER: Token = Token(0);
const CLIENT: Token = Token(1);

// Define a handler to process the events
struct WebSocketHandler(TcpListener);

impl Handler for WebSocketHandler {
    type Timeout = ();
    type Message = ();

    fn readable(&mut self, event_loop: &mut EventLoop<WebSocketHandler>, token: Token, _: ReadHint) {
        println!("New Client");
        match token {
            SERVER => {
                let WebSocketHandler(ref mut server) = *self;
                // Accept and drop the socket immediately, this will close
                // the socket and notify the client of the EOF.
                let mut stream: TcpStream = server.accept().unwrap().unwrap();
                
                // let data = ['h' as u8, 'e' as u8, 'l' as u8, 'l' as u8, 'o' as u8];
                // println!("{:?}", data);
                // let res = stream.write(&data);
                // println!("{:?}", res);

                let buf = &mut [0u8; 255];
                let size = stream.read(buf).unwrap();
                for x in 0..size {
                    print!("{:#X} ", buf[x]);
                }
                println!("");
            }
            CLIENT => {
                // The server just shuts down the socket, let's just
                // shutdown the event loop
                event_loop.shutdown();
            }
            _ => panic!("unexpected token"),
        }
    }
}

fn main() {
    let addr = "0.0.0.0:1337".parse().unwrap();

    // Setup the server socket
    let server = TcpListener::bind(&addr).unwrap();
    // Create an event loop
    let mut event_loop = EventLoop::new().unwrap();
    // Start listening for incoming connections
    event_loop.register(&server, SERVER).unwrap();

    // Setup the client socket
    // let sock = TcpStream::connect(&addr).unwrap();
    // Register the socket
    // event_loop.register(&sock, CLIENT).unwrap();

    println!("Starting Server on {:?}", addr);
    // Start handling events
    event_loop.run(&mut WebSocketHandler(server)).unwrap();
    // loop {
    //     println!("Doing things...");
    // }
}
