module ApplicationHelper
  include Pagy::Frontend

def tooltip(text, html=false)
  text = text.gsub(/"/, "&quot;")
  %{
    data-bs-toggle="tooltip" data-bs-html="#{ html.inspect }" data-bs-placement="top" title="#{text}"
  }.html_safe
end

def popover(title, text, html=false)
  title = title.gsub(/"/, "&quot;")
  text  = text.gsub(/"/, "&quot;")
  %{
     tabindex="0" cursor="help" data-bs-toggle="popover" data-bs-trigger="focus" data-bs-html="#{html.inspect}" title="#{title}" data-bs-content="#{text}"
  }.html_safe
end

  def icon(name)
    %{
      <svg class="bi flex-shrink-0 me-2"
        width="24" height="24"
        role="img" aria-label="#{name}:">
          <use xlink:href="##{name}"/>
      </svg>
    }.html_safe
  end

  def money(money)
    money = 0 unless money
    if money < 0
      "-" + number_to_currency(-money)
    else
      number_to_currency(money)
    end
  end

  def name_from_author(a)
    if a
      [a.salutation, a.first_name, a.middle_initials, a.last_name ].compact.reject(&:empty?).join(' ')
    else
      "Administrator"
    end
  end

  MISSING = "https://static.pragprog.com/covers/MISSING/144/750.jpg"

  def cover_with_default(code)
      image_tag("https://static.pragprog.com/covers/#{code}/144/750.jpg",
                onerror: "this.src='#{MISSING}';this.onerror=''")
  end
end
