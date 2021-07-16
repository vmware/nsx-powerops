import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ManagerInfosComponent } from './manager-infos.component';

describe('ManagerInfosComponent', () => {
  let component: ManagerInfosComponent;
  let fixture: ComponentFixture<ManagerInfosComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ ManagerInfosComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(ManagerInfosComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
