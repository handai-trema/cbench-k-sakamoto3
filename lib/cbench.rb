# A simple openflow controller for benchmarking.
require 'ruby-prof'

class Cbench < Trema::Controller
  def start(_args)
    logger.info 'Cbench started.'
  end

  def packet_in(datapath_id, message)
    RubyPorf.start
    send_flow_mod_add(
      datapath_id,
      match: ExactMatch.new(message),
      buffer_id: message.buffer_id,
      actions: SendOutPort.new(message.in_port + 1)
    )
    result = RubyProf.stop
    RubyProf::FlatPrinter.new(result).print(STDOUT)
  end
end
