module Ethereum

  class Deployment

    class MissingDeploymentTxIdError < ArgumentError
      def message
        "Can't initialize a Deployment object with a null TX ID"
      end
    end

    DEBUG = true
    # DEBUG = false # should be default

    attr_accessor :id, :contract_address, :connection, :deployed, :mined, :valid_deployment

    def initialize(txid, connection)
      @id = txid
      unless @id
        puts "Error: (stacktrace)"
        puts caller
        puts
        raise MissingDeploymentTxIdError
      end
      @connection = connection
      @deployed = false
      @contract_address = nil
      @valid_deployment = false
    end

    def mined?
      return true if @mined
      tx = @connection.eth_get_transaction_by_hash(@id)
      puts "Deployment TX: #{tx} - TX id: #{@id}" if DEBUG
      @mined = tx && tx["result"] && tx["result"]["blockNumber"].present?
      @mined ||= false
    end

    def has_address?
      return true if @contract_address.present?
      return false unless self.mined?
      @contract_address ||= @connection.eth_get_transaction_receipt(@id)["result"]["contractAddress"]
      return @contract_address.present?
    end

    def deployed?
      return true if @valid_deployment
      return false unless self.has_address?
      puts "contract address: #{@contract_address}" if DEBUG
      # p @connection.eth_get_code(@contract_address, "earliest")
      @valid_deployment = @connection.eth_get_code(@contract_address)["result"] == "0x"
    end

    def wait_for_deployment(timeout = 1500.seconds)
      start_time = Time.now
      while self.deployed? == false
        raise "Transaction #{@id} timed out." if ((Time.now - start_time) > timeout)
        sleep 1
        return true if self.deployed?
      end
    end

  end

end
