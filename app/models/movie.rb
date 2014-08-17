class Movie
  attr_accessor :title, :year, :cd_num

  def dir_name()
    return "#{@title}.(#{@year})"
  end

  def out_file_name()
    if @cd_num == 0
      return dir_name()
    else
      return "#{@title}.(#{@year}).cd#{@cd_num}"
    end
  end

  def initialize()
    @cd_num = 0 # Zero indicates that it is not a multipart movie file
  end

end
