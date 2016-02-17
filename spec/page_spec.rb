RSpec.describe Fauna::Page do
  before(:all) do
    create_test_db
    @test_class = client.query { create ref('classes'), name: 'page_test' }[:ref]

    index_all = client.query { create ref('indexes'), name: 'page_all', source: @test_class }

    wait_for_active(index_all[:ref])

    @test_index = index_all[:ref]

    @instances = client.query { (1..3).collect { |x| create(@test_class, data: { value: x }) } }
    @instance_refs = @instances.collect { |instance| instance[:ref] }

    @test_match = Fauna::Query.match(@test_index)
  end

  after(:all) do
    destroy_test_db
  end

  def get_var(page, field)
    page.instance_variable_get(field)
  end

  def get_param(page, field)
    get_var(page, :@page_params)[field]
  end

  def get_cursor(page)
    get_var(page, :@page_params).select { |key, _| [:before, :after].include? key }
  end

  def get_fauna_map(page)
    get_var(page, :@fauna_map)
  end

  def get_ruby_map(page)
    get_var(page, :@ruby_map)
  end

  describe 'builders' do
    describe '#with_ts' do
      let(:ts1) { random_number }
      let(:ts2) { random_number }

      it 'sets ts on copy' do
        page = Fauna::Page.new(client, @test_match, ts: ts1)

        expect(get_param(page.with_ts(ts2), :ts)).to eq(ts2)
        expect(get_param(page, :ts)).to eq(ts1)
      end
    end

    describe '#with_cursor' do
      let(:ref1) { random_ref }
      let(:ref2) { random_ref }

      it 'sets cursor on copy' do
        page = Fauna::Page.new(client, @test_match, before: ref1)

        expect(get_cursor(page.with_cursor(before: ref2))).to eq(before: ref2)
        expect(get_cursor(page)).to eq(before: ref1)
      end

      it 'reverses cursor' do
        page = Fauna::Page.new(client, @test_match, before: ref1)

        expect(get_cursor(page.with_cursor(after: ref2))).to eq(after: ref2)
        expect(get_cursor(page)).to eq(before: ref1)
      end

      it 'preserves nil' do
        page = Fauna::Page.new(client, @test_match, after: nil)

        expect(get_cursor(page.with_cursor(before: nil))).to eq(before: nil)
        expect(get_cursor(page)).to eq(after: nil)
      end

      it 'resets paging' do
        page = Fauna::Page.new(client, @test_match, size: 1)
        page1 = page.next

        page2 = page1.with_cursor(after: 0).next

        expect(page2.data).to eq(page2.data)
      end
    end

    describe '#with_size' do
      let(:size1) { random_number }
      let(:size2) { random_number }

      it 'sets size on copy' do
        page = Fauna::Page.new(client, @test_match, size: size1)

        expect(get_param(page.with_size(size2), :size)).to eq(size2)
        expect(get_param(page, :size)).to eq(size1)
      end
    end

    describe '#with_events' do
      it 'sets events on copy' do
        page = Fauna::Page.new(client, @test_match, events: false)

        expect(get_param(page.with_events(true), :events)).to be(true)
        expect(get_param(page, :events)).to be(false)
      end
    end

    describe '#with_sources' do
      it 'sets sources on copy' do
        page = Fauna::Page.new(client, @test_match, sources: false)

        expect(get_param(page.with_sources(true), :sources)).to be(true)
        expect(get_param(page, :sources)).to be(false)
      end
    end

    describe '#with_fauna_map' do
      it 'sets fauna map on copy' do
        page = Fauna::Page.new(client, @test_match)

        expect(get_fauna_map(page.with_fauna_map { |page_q| map(page_q) { |ref| get ref } })).not_to eq(get_fauna_map(page))
      end
    end

    describe '#with_ruby_map' do
      it 'sets ruby map on copy' do
        page = Fauna::Page.new(client, @test_match)

        expect(get_ruby_map(page.with_ruby_map { |ref| ref.id })).not_to eq(get_ruby_map(page))
      end
    end
  end

  describe '#next' do
    it 'returns next page' do
      page = Fauna::Page.new(client, @test_match, size: 1, after: 0)

      @instance_refs.each do |ref|
        page = page.next
        expect(page.data.first).to eq(ref)
      end
    end

    it 'returns nil on last page' do
      page = Fauna::Page.new(client, @test_match, size: 1, after: @instance_refs.last).next

      expect(page.next).to be_nil
    end
  end

  describe '#prev' do
    it 'returns prev page' do
      page = Fauna::Page.new(client, @test_match, size: 1, before: nil)

      @instance_refs.reverse_each do |ref|
        page = page.prev
        expect(page.data.first).to eq(ref)
      end
    end

    it 'returns nil on last page' do
      page = Fauna::Page.new(client, @test_match, size: 1, before: @instance_refs.first).prev

      expect(page.prev).to be_nil
    end
  end

  context 'without cursor' do
    it 'next and prev returns the same page' do
      page = Fauna::Page.new(client, @test_match, size: 1)

      next_page = page.next
      expect(next_page).not_to be_nil

      prev_page = page.prev
      expect(prev_page).to eq(next_page)
    end
  end

  it 'pages both directions' do
    page = Fauna::Page.new(client, @test_match, size: 1, after: 0).next
    expect(page.data.first).to eq(@instance_refs[0])

    page = page.next
    expect(page.data.first).to eq(@instance_refs[1])

    page = page.prev
    expect(page.data.first).to eq(@instance_refs[0])
  end

  describe '#each' do
    it 'iterates the set in the after direction' do
      page = Fauna::Page.new(client, @test_match, size: 1)
      refs = @instance_refs.collect { |ref| [ref] }

      expect(page.each.collect { |ref| ref }).to eq(refs)
    end

    context 'with fauna map' do
      it 'iterates the set using the fauna map' do
        page = Fauna::Page.new(client, @test_match, size: 1) { |page_q| map(page_q) { |ref| get(ref) } }
        instances = @instances.collect { |inst| [inst] }

        expect(page.each.collect { |inst| inst }).to eq(instances)
      end
    end

    context 'with ruby map' do
      it 'iterates the set using the ruby map' do
        page = Fauna::Page.new(client, @test_match, size: 1).with_ruby_map { |ref| ref.id }
        ids = @instance_refs.collect { |ref| [ref.id] }

        expect(page.each.collect { |id| id }).to eq(ids)
      end
    end
  end

  describe '#reverse_each' do
    it 'iterates the set in the before direction' do
      page = Fauna::Page.new(client, @test_match, size: 1, before: nil)
      refs = @instance_refs.reverse.collect { |ref| [ref] }

      expect(page.reverse_each.collect { |ref| ref }).to eq(refs)
    end
  end
end
