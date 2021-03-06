# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def cover_from_amazon_asin(asin, size=40)
    tag(:img, :src => "http://ec1.images-amazon.com/images/P/#{asin}.01.MZZZZZZZ.jpg", :height => size, :width => size)
  end

  def cover_img_tag(record_with_cover, size=40)
    if record_with_cover.amazon_asin
      cover_from_amazon_asin(record_with_cover.amazon_asin, size)
    elsif record_with_cover.cover
      tag(:img, :src => record_with_cover.public_cover_path, :height => size)
    else
      tag(:img, :src => 'images/unknow_cover.png', :height => size)
    end
  end

  def album_name_with_link(album)
    content_tag(:span, h(album.artist), :class => 'artist') +
    link_to(h(album.name), album_path(album), :class => 'album_name')
  end

  def album_div(album)
    content_tag(:div,
      content_tag(:div,
        cover_img_tag(album) +
        content_tag(:div, "▲", :class => "pointer"),
        :class => 'in_first_line') +
      content_tag(:div, album_name_with_link(album), :class => "info"),
      :class => 'cover_album')
  end


  def no_one_or_n_comments(comments)
    case comments.length
    when 0 then "Aucun commentaire"
    when 1 then "1 commentaire"
    else "#{comments.length} commentaires"
    end
  end

end
