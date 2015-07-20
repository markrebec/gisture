module Gisture
  module Cloneable
    def clone_path
      @clone_path ||= ::File.join(Gisture.configuration.tmpdir, owner, name)
    end

    def clone!(&block)
      destroy_clone!
      clone(&block)
    end

    def clone(&block)
      return self if cloned?

      Gisture.logger.info "[gisture] Cloning #{owner}/#{name} into #{clone_path}"
      Git.clone(clone_url, name, path: ::File.dirname(clone_path))
      stamp_clone!

      if block_given?
        instance_eval &block
        destroy_clone!
      end

      self
    end

    # removes the .git path and adds a .gisture stamp
    def stamp_clone!
      FileUtils.rm_rf("#{clone_path}/.git")
      ::File.write("#{clone_path}/.gisture", Time.now.to_i.to_s)
    end

    def destroy_clone!
      FileUtils.rm_rf(clone_path)
    end
    alias_method :destroy_cloned_files!, :destroy_clone!

    def cloned?
      ::File.read("#{clone_path}/.gisture").strip
    rescue
      false
    end
  end
end
