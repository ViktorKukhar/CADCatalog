module ApplicationHelper
  def all_tags
    Tag.all
  end

  def all_softwares
    Software.all
  end
end
