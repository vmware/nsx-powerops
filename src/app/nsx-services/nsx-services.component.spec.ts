import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NsxServicesComponent } from './nsx-services.component';

describe('NsxServicesComponent', () => {
  let component: NsxServicesComponent;
  let fixture: ComponentFixture<NsxServicesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NsxServicesComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NsxServicesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
