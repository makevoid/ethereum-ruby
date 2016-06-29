module Ethereum

  class Initializer
    attr_accessor :contracts, :file, :client

    def initialize(file, client = Ethereum::IpcClient.new, use_solc_binary: false)
      @file = File.read(file)
      @client = client
      if use_solc_binary
        sol_output = @client.compile_solidity(@file)
        raise "Solc compile error: #{sol_output["error"]["message"]}" if sol_output["error"]
        contracts = sol_output["result"].keys
        @contracts = []
        contracts.each do |contract|
          abi = sol_output["result"][contract]["info"]["abiDefinition"]
          name = contract
          code = sol_output["result"][contract]["code"]
          @contracts << Ethereum::Contract.new(name, code, abi)
        end
      else
        solc = "solc"
        # solc = "/usr/bin/solc"
        cmd = "mkdir -p /tmp/contracts_compiled"
        puts `#{cmd}`
        cmd = "#{solc} --bin --abi #{file} -o /tmp/contracts_compiled/"
        puts `#{cmd}`
        @contracts = []
        # TODO: map trhough all contracts
        name = File.basename file, ".sol"
        abi = File.read "/tmp/contracts_compiled/#{name}.abi"
        abi = JSON.parse abi
        code = @file
        @contracts << Ethereum::Contract.new(name, code, abi)
      end
    end

    def build_all
      @contracts.each do |contract|
        contract.build(@client)
      end
    end

  end
end
