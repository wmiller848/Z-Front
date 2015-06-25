mediaHandle
mediaHandle.draw
mediaHandle.displays // n number of webgl canvas
mediaHandle.pipe // a single tcp connection to the server
mediaHandle.pipe.streams // the demuxed streams from the pipe
mediaHandle.decoder // a reference to the libvpx decoder

// Network IO
mediaHandle.pipe.write(bytes) {
  // Demux the data
  steam_bytes = demux(bytes)
  each steam_bytes | {steam_id, s_bytes} streams[steam_id].write(s_bytes)
}

// From the network
mediaHandle.pipe.stream.write(s_bytes) {
  // Put into buffer
  self.buffer.concat(s_bytes)
}

// Draw
mediaHandle.draw(display_id, stream_id) {
  // Decode the latest frame from the stream
  stream_pixels = mediaHandle.decoder.decode(
    mediaHandle.pipe.streams[stream_id].f_index,
    mediaHandle.pipe.streams[stream_id].buffer
  )
  mediaHandle.display[display_id].draw(stream_pixels)
}
