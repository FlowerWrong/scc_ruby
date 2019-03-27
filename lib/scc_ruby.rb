require 'scc_ruby/version'
require 'net/http'
require 'json'

module SccRuby
  class Api
    def self.fetch(config_server_url, app_name, app_env = 'default')
      uri = URI(build_url(config_server_url, app_name, app_env))
      res = Net::HTTP.get_response(uri)

      if res.code != '200'
        raise "Fail to fetch from spring cloud config server, http code #{res.code}, message #{res.message}"
      end

      json = JSON.parse(res.body)
      h = json['propertySources'].inject(:merge!)['source']

      # try to fix yaml array
      arr_keys = []
      h.keys.each do |k|
        sp = k.split(/\[\d+/)
        arr_keys << sp[0] if (sp.size > 1) && (sp[1] == ']')
      end

      arr_keys.each do |k|
        h[k] = []
      end

      h.each do |k, v|
        next if v.is_a?(Array)

        arr_keys.each do |ak|
          if k.split(/\[\d+/)[0] == ak
            h[ak] << v
            h.delete(k)
          end
        end
      end
      # h.each do |k, v|
      #   h[k] = v.to_s if v.is_a?(Integer)
      #   h[k] = v.map(&:to_s) if v.is_a?(Array)
      # end
      h
    end

    def self.build_url(config_server_url, app_name, app_env)
      "#{config_server_url}/#{app_name}/#{app_env}"
    end
  end
end
