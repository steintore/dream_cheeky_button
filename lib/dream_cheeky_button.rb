require 'libusb'

class DreamCheekyButton

  def self.run(&block)
    button = new
    button.instance_eval(&block)
    button.run
  end

  def open(&block)
    @lid_opened_callback = block
  end

  def close(&block)
    @lid_closed_callback = block
  end

  def push(&block)
    @button_pushed_callback = block
  end

  def run
    poll_usb
  end

  private

  attr_accessor :prior_state, :current_state, :open_or_closed

  PRODUCT_ID = 0x0d
  VENDOR_ID = 0x1D34

  CLOSED = 0x15
  OPEN = 0x17
  DEPRESSED = 0x16

  def initialize
    @device = find_device
  end

  def poll_usb
    init_loop
    begin
      case check_button
        when OPEN
          open! unless already_open?
        when DEPRESSED
          push! unless already_pushed?
        when CLOSED
          close! unless already_closed?
      end
      sleep 0.1
    end while (true)
  end

  def find_device
    usb = LIBUSB::Context.new
    device = usb.devices(:idVendor => VENDOR_ID, :idProduct => PRODUCT_ID).first
    if device.nil? 
      puts "Device not found" if device.nil?
      return nil
    end
    puts "Device found: #{device}" 
    device
  end

  def open_connection
    close_connection
    begin
      @handle = @device.open
      @handle.usb_detach_kernel_driver_np(0, 0) rescue nil
      @handle.usb_claim_interface(0)

      @open = true
    rescue
      false
    end
  end

  def close_connection
    return true unless @open
    @handle.usb_release_interface(0)
    @handle.usb_close
    @open = false
    true
  end


  def init_loop
    self.prior_state = @current_state = read
    self.open_or_closed = DEPRESSED == prior_state ? OPEN : prior_state
  end

  def check_button
    self.prior_state = @current_state
    @current_state = read
  end

  def open!
    self.open_or_closed = OPEN
    @lid_opened_callback && @lid_opened_callback.call
  end

  def push!
    @button_pushed_callback && @button_pushed_callback.call
  end

  def close!
    self.open_or_closed = CLOSED
    @lid_closed_callback && @lid_closed_callback.call
  end

  def already_pushed?
    DEPRESSED == prior_state
  end

  def already_closed?
    CLOSED == open_or_closed
  end

  def already_open?
    OPEN == open_or_closed
  end

  def read
    begin
      open_connection unless @open
      bytes = "\x00\x00\x00\x00\x00\x00\x00\x02"
      char = (0..7).to_a.pack('C*')

      @handle.usb_control_msg("0x21".to_i(16), "0x09".to_i(16), "0x0200".to_i(16), 0, bytes, 10)

      @handle.usb_interrupt_read(@device.endpoints.first.bEndpointAddress, char, 10)

      char.unpack('C*')[0]
    rescue Exception => e
      begin
        @handle.usb_reset
        @open = false
      rescue Exception => e2
        close_connection
        exit(1)
      end

    end

  end

end
